#!/usr/bin/env python3
"""Manage only this plugin's PulseAudio/PipeWire loopback."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys

MARKER = 'application.id=io.github.mattbudde.kata'
LEGACY_MARKER = 'application.id=local.katana-go'


def pactl(*args):
    return subprocess.run(['pactl', *args], check=True, capture_output=True,
                          text=True, timeout=8).stdout.strip()


def listing(kind):
    return json.loads(pactl('--format=json', 'list', kind))


def is_katana(device):
    return 'katana' in device['name'].lower() and 'go' in device['name'].lower()


def sources():
    return [s for s in listing('sources') if is_katana(s)
            and not s['name'].endswith('.monitor')]


def modules():
    result = []
    # PipeWire's JSON module list can omit the index needed for unloading.
    for line in pactl('list', 'short', 'modules').splitlines():
        fields = line.split('\t')
        if (len(fields) >= 3 and fields[1] == 'module-loopback'
                and any(('sink_input_properties=' + marker) in fields[2].split()
                        for marker in (MARKER, LEGACY_MARKER))):
            result.append({'index': int(fields[0]),
                           'sink': next((v[5:] for v in fields[2].split()
                                         if v.startswith('sink=')), '')})
    return result


def disable():
    for module in modules():
        pactl('unload-module', str(module['index']))


def enable():
    inputs = sources()
    if not inputs:
        raise RuntimeError('Connect the BOSS Katana GO via USB first.')
    sinks = [s for s in listing('sinks') if not is_katana(s)]
    if not sinks:
        raise RuntimeError('No computer speaker or headphone output is available.')
    default = pactl('get-default-sink')
    sink = next((s for s in sinks if s['name'] == default), sinks[0])
    pactl('load-module', 'module-loopback', 'source=' + inputs[0]['name'],
          'sink=' + sink['name'], 'latency_msec=20',
          'source_dont_move=true', 'sink_dont_move=true',
          'sink_input_properties=' + MARKER)


def status():
    inputs = sources()
    routes = modules()
    connected = bool(inputs)
    active = connected and bool(routes)
    sinks = [s for s in listing('sinks') if not is_katana(s)]
    default = pactl('get-default-sink') if sinks else ''
    target = routes[0]['sink'] if routes else default
    output = next((s for s in sinks if s['name'] == target), None)
    if not routes and not output and sinks:
        output = sinks[0]
    return {'connected': connected, 'active': active,
            'routeExists': bool(routes),
            'input': inputs[0].get('description', 'BOSS Katana GO') if inputs else '',
            'output': output.get('description', output['name']) if output else '',
            'message': ('Monitoring on' if active else 'Monitoring off')
            if connected else 'Katana GO disconnected'}


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'status'
    if action not in ('status', 'toggle', 'on', 'off'):
        raise RuntimeError('Usage: katana-go.py [status|toggle|on|off]')
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
    with (runtime / 'katana-go.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if action == 'off':
            disable()
        elif action == 'on':
            if not modules():
                enable()
        elif action == 'toggle':
            if modules():
                disable()
            else:
                enable()
        print(json.dumps(status()))


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError, ValueError) as error:
        print(json.dumps({'active': False, 'connected': False, 'error': True,
                          'message': str(error)}))
        sys.exit(1)
