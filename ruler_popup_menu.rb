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

class RulerPopupMenu < GladeWindow
	def initialize
		super('ruler_popup_menu', :widgets => [:keep_above_menuitem, :track_mouse_menuitem, :unit_pixels_menuitem, :unit_centimeters_menuitem, :unit_inches_menuitem, :unit_picas_menuitem, :unit_points_menuitem, :unit_percentage_menuitem])
		@unit_menuitems = {
			UNIT_PIXELS => @unit_pixels_menuitem,
			UNIT_CENTIMETERS => @unit_centimeters_menuitem,
			UNIT_INCHES => @unit_inches_menuitem,
			UNIT_PICAS => @unit_picas_menuitem,
			UNIT_POINTS => @unit_points_menuitem,
			UNIT_PERCENTAGE => @unit_percentage_menuitem
		}.freeze
	end

	def track_mouse=(val)
		@track_mouse_menuitem.active = val
	end

	def track_mouse?
		return @track_mouse_menuitem.active?
	end

	def keep_above=(val)
		@keep_above_menuitem.active = val
	end

	def keep_above?
		return @keep_above_menuitem.active?
	end

	def popup(root_x, root_y, x, y, time)
		@click_properties = [root_x, root_y, x, y, time]		# save for rotation point
		super(nil, nil, MOUSE_BUTTON_3, time)
	end

	def unit
		@unit_menuitems.each_pair { | unit, menuitem | return unit if menuitem.active? }
	end

	def unit=(value)
		@unit_menuitems[value].active = true
	end

	###################################################################
	# Settings
	###################################################################
	def read_settings(settings)
		self.track_mouse = (settings['track_mouse'] || false)
		self.keep_above = (settings['keep_above'] || false)
		self.unit = (settings['metric'] || UNIT_PIXELS)
	end

	def write_settings(settings)
		settings['track_mouse'] = track_mouse?
		settings['metric'] = unit
		settings['keep_above'] = keep_above?
	end

private

	###################################################################
	# Signal Handlers for menu items
	###################################################################

	def on_preferences_activate
		$preferences_window.present
	end

	def on_track_mouse_activate
		$ruler_window.show_measurement_tooltip = track_mouse?
	end

	def on_keep_above_activate
		$ruler_window.keep_above = keep_above?
		$preferences_window.keep_above = keep_above?	# confusing if preferences won't go above ruler
	end

	def on_rotate_activate
		$ruler_window.rotate(*(@click_properties[0..3]))		# send first 4 items
	end

	def on_style_changed
		$ruler_window.redraw
	end

	def on_help_menuitem_activate
		$help_window.present
	end

	def on_about_activate
		Gtk::AboutDialog.show(nil, :logo => APP_ICON_LIST.last, :program_name => APP_NAME, :copyright => APP_COPYRIGHT, :version => APP_VERSION, :authors => APP_AUTHORS, :artists => APP_ARTISTS)
	end

	def on_quit_activate
		Gtk.main_quit
	end
end

# Local Variables:
# tab-width: 2
# End:
