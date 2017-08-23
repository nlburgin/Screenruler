 ###############################################################################
 #  Copyright 2011 Ian McIntosh <ian@openanswers.org>
 #
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU Library General Public License for more details.
 #
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 ###############################################################################

require 'glade_window'

class PreferencesWindow < GladeWindow
	DEFAULT_FOREGROUND_COLOR = '#202020'
	DEFAULT_BACKGROUND_COLOR = '#E6E36B'
	DEFAULT_OPACITY = 0.85

	MM_TO_INCHES = (1.0 / 25.4)		# 1 inch = 25.4 millimeters

	def initialize
		super('preferences_window', :widgets => [:foreground_color_button, :background_color_button, :text_fontbutton, :system_ppi_setting_label, :use_custom_ppi_radiobutton, :custom_ppi_settings_container, :ppi_horizontal_spinbutton, :ppi_vertical_spinbutton])

		# GTK signal handlers
		@window.signal_connect('delete_event') { hide }

		@system_ppi_setting_label.markup = sprintf("(%d x %d)", system_ppi_horizontal, system_ppi_vertical)

		on_key_press(Gdk::Keyval::GDK_Escape) { hide }
	end

	def foreground_color ; return @foreground_color_button.color ; end
	def background_color ; return @background_color_button.color ; end
	def font ; return @text_fontbutton.font_name ; end
	def watch_mouse? ; return @watch_mouse_checkbutton.active? ; end
	def watch_mouse=(value) ; @watch_mouse_checkbutton.active = value ; end
	attr_reader :opacity

	def ppi_horizontal
		if @use_custom_ppi_radiobutton.active?
			@ppi_horizontal_spinbutton.value
		else
			system_ppi_horizontal
		end
	end

	def ppi_vertical
		if @use_custom_ppi_radiobutton.active?
			@ppi_vertical_spinbutton.value
		else
			system_ppi_vertical
		end
	end

	def system_ppi_horizontal ; Gdk::Screen.default.width / (Gdk::Screen.default.width_mm * MM_TO_INCHES) ; end
	def system_ppi_vertical ; Gdk::Screen.default.width / (Gdk::Screen.default.width_mm * MM_TO_INCHES) ; end

	###################################################################
	# Settings
	###################################################################
	def read_settings(settings)
		@foreground_color_button.color = Gdk::Color.parse(settings['foreground_color'] || DEFAULT_FOREGROUND_COLOR)
		@background_color_button.color = Gdk::Color.parse(settings['background_color'] || DEFAULT_BACKGROUND_COLOR)
		@text_fontbutton.font_name = settings['font'] if settings['font']
		@opacity = settings['opacity'] || DEFAULT_OPACITY
		@ppi_horizontal_spinbutton.value = settings['horizontal_pixels_per_inch'] || system_ppi_horizontal
		@ppi_vertical_spinbutton.value = settings['vertical_pixels_per_inch'] || system_ppi_vertical
		@use_custom_ppi_radiobutton.active = (settings['use_custom_pixels_per_inch'] || false)
	end

	def write_settings(settings)
		settings['foreground_color'] = self.foreground_color.to_hex
		settings['background_color'] = self.background_color.to_hex
		settings['font'] = self.font
		settings['opacity'] = @opacity
		settings['use_custom_pixels_per_inch'] = @use_custom_ppi_radiobutton.active?
		settings['horizontal_pixels_per_inch'] = @ppi_horizontal_spinbutton.value
		settings['vertical_pixels_per_inch'] = @ppi_vertical_spinbutton.value
	end

	def present
		super ; super ; super		# TODO: remove this hack when it's no longer needed to prevent window from popping up UNDER the ruler (on Ubuntu 8.04)
	end

private

	###################################################################
	# Signal Handlers
	###################################################################
	def on_style_changed
		$ruler_window.redraw
	end

	def on_ppi_vertical_spinbutton_changed
		on_style_changed
	end

	def on_ppi_horizontal_spinbutton_changed
		on_style_changed
	end

	def on_use_custom_ppi_radiobutton_toggled
		@custom_ppi_settings_container.sensitive = @use_custom_ppi_radiobutton.active?
		@system_ppi_setting_label.sensitive = !@use_custom_ppi_radiobutton.active?
		on_style_changed
	end

	def on_close_clicked
		hide
	end
end

# Local Variables:
# tab-width: 2
# End:
