import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('monitor', Path(__file__).parents[1] / 'katana-go.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class MonitorTests(unittest.TestCase):
    def test_monitor_sources_are_excluded(self):
        with patch.object(m, 'listing', return_value=[
            {'name': 'alsa_input.usb-BOSS_KATANA_GO-00.analog-stereo'},
            {'name': 'alsa_output.usb-BOSS_KATANA_GO-00.analog-stereo.monitor'},
            {'name': 'microphone'}]):
            self.assertEqual(len(m.sources()), 1)
            self.assertTrue(m.sources()[0]['name'].startswith('alsa_input'))

    def test_off_only_unloads_owned_loopbacks(self):
        rows = '3\tmodule-loopback\tsource=other\n4\tmodule-loopback\tsink_input_properties=' + m.MARKER
        with patch.object(m, 'pactl', side_effect=[rows, '']) as call:
            m.disable()
            self.assertEqual(call.call_args.args, ('unload-module', '4'))

    def test_katana_default_output_falls_back_to_computer(self):
        with patch.object(m, 'sources', return_value=[{'name': 'katana_capture'}]), \
             patch.object(m, 'listing', return_value=[{'name': 'usb_BOSS_KATANA_GO'}, {'name': 'speakers'}]), \
             patch.object(m, 'pactl', return_value='usb_BOSS_KATANA_GO') as call:
            m.enable()
            self.assertIn('sink=speakers', call.call_args.args)
            self.assertIn('source=katana_capture', call.call_args.args)

    def test_disconnected_does_not_create_loopback(self):
        with patch.object(m, 'sources', return_value=[]), patch.object(m, 'pactl') as call:
            with self.assertRaisesRegex(RuntimeError, 'Connect'):
                m.enable()
            call.assert_not_called()

    def test_status_reports_actual_route_after_default_changes(self):
        with patch.object(m, 'sources', return_value=[{'name': 'katana_capture'}]), \
             patch.object(m, 'modules', return_value=[{'index': 4, 'sink': 'speakers'}]), \
             patch.object(m, 'listing', return_value=[
                 {'name': 'speakers', 'description': 'Computer speakers'},
                 {'name': 'headphones', 'description': 'Headphones'}]), \
             patch.object(m, 'pactl', return_value='headphones'):
            state = m.status()
            self.assertTrue(state['active'])
            self.assertEqual(state['output'], 'Computer speakers')

    def test_disconnected_status_allows_stopping_stale_route(self):
        with patch.object(m, 'sources', return_value=[]), \
             patch.object(m, 'modules', return_value=[{'index': 4, 'sink': 'speakers'}]), \
             patch.object(m, 'listing', return_value=[]):
            state = m.status()
            self.assertFalse(state['active'])
            self.assertFalse(state['connected'])
            self.assertTrue(state['routeExists'])


if __name__ == '__main__':
    unittest.main()
