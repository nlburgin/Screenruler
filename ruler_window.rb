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

require 'glade_window', 'canvas', 'unique_timeout'
require_relative 'ruler_popup_menu'

Unit = Struct.new('Unit', :name, :tick_pattern, :units_per_pattern_repetition, :per_inch)

class RulerWindow < GladeWindow
	DEFAULT_RULER_LENGTH = 600

	MOVE_SMALL, MOVE_LARGE = 1, 15
	GROW_SMALL, GROW_LARGE = 1, 15

	ORIENTATION_LEFT, ORIENTATION_UP = 'left', 'up'		# where the value '0 pixels' is

	MENU_BOX_WIDTH, MENU_BOX_HEIGHT = 10, 10
	MENU_BOX_RELIEF = 10															# distance from edge

	OVERDRAW = 200		# ensures that final tick labels get drawn, even when the tick itself is past the window

	MEASUREMENT_TOOLTIP_UPDATE_FREQUENCY = 80					# in milliseconds

	@@unit_settings = {
		UNIT_INCHES				=> Unit.new(_('in'), 'MMMLMMML',			1,	1),
		UNIT_CENTIMETERS	=> Unit.new(_('cm'), 'MMMMLMMMML', 	1,	0.3937),
		UNIT_PICAS				=> Unit.new(_('pc'), 'MMLMML', 			6,	0.1667),
		UNIT_POINTS				=> Unit.new(_('pt'), 'MMMMMLMMMMML',	72,	0.0139),
		UNIT_PIXELS				=> Unit.new(_('px'), 'SSSSMSSSSMSSSSMSSSSMSSSSL' * 2, 100, -1),	# :per_inch not used...
		UNIT_PERCENTAGE		=> Unit.new(_('%'),  'ML',						10,	-1)											# ...ditto
	}.freeze

	@@tick_sizes = {'S' => 4, 'M' => 7, 'L' => 10}.freeze		# length of tick marks (in pixels) in above patterns

	def initialize
		super('ruler_window')

		self.icon_list = APP_ICON_LIST

		# Fill our window with a DrawingArea to render the ruler
		@canvas = Canvas.new.set_draw_proc { |cr| draw(cr) }
		@window << @canvas.widget

		@mouse_is_in_window = false							# we'll get a notify right away if mouse begins in the window
		@orientation = ORIENTATION_LEFT

		configure_ppi
		configure_orientation

		# GTK signal handlers (others hooked up by Glade)
		@canvas.widget.add_events(Gdk::Event::ENTER_NOTIFY_MASK).signal_connect('enter_notify_event') { self.mouse_is_in_window = true }
		@canvas.widget.add_events(Gdk::Event::LEAVE_NOTIFY_MASK).signal_connect('leave_notify_event') { self.mouse_is_in_window = false }

		@measurement_tooltip_timeout = UniqueTimeout.new(MEASUREMENT_TOOLTIP_UPDATE_FREQUENCY) { update_measurement_tooltip }
	end

	def present
		super
		self.opacity = $preferences_window.opacity if self.respond_to? :opacity=
	end

	def show_measurement_tooltip=(val)
		if val
			@measurement_tooltip_timeout.start
		else
			@measurement_tooltip_timeout.stop
		end
		@enable_mouse_tracking = val
		redraw
	end

	def update_measurement_tooltip
		# Force a redraw if mouse has moved
		__window__unused__, mouse_x, mouse_y, key_mask = Gdk::Window.default_root_window.pointer
		if mouse_x != @previous_mouse_x or mouse_y != @previous_mouse_y or key_mask != @previous_key_mask
			# save for later comparison
			@previous_mouse_x, @previous_mouse_y, @previous_key_mask = mouse_x, mouse_y, key_mask
			redraw
		end
	end

	def progress_pixels_to_unit_string(progress_pixels)
		unit = @@unit_settings[$ruler_popup_menu.unit]

		case $ruler_popup_menu.unit
		when UNIT_PIXELS
			sprintf("%d %s", progress_pixels, unit.name)
		when UNIT_PERCENTAGE
			sprintf("%3.1f %%", 100.0 * progress_pixels.to_f / length.to_f)
		else
			sprintf("%3.2f %s", (progress_pixels.to_f / pixels_per_inch) / unit.per_inch, unit.name)
		end
	end

	def on_delete_event
		Gtk.main_quit
		true	# handled
	end

	def length
		case @orientation
			when ORIENTATION_LEFT	then @canvas.width
			when ORIENTATION_UP		then @canvas.height
		end
	end

	def length=(value)
		grow(value - length)
	end

	def pixels_per_inch
		case @orientation
			when ORIENTATION_LEFT	then $preferences_window.ppi_horizontal
			when ORIENTATION_UP		then $preferences_window.ppi_vertical
		end
	end

	def redraw
		@canvas.redraw
	end

	def rotate(root_x, root_y, window_x, window_y)
		case @orientation
			when ORIENTATION_LEFT		# rotate to ORIENTATION_UP
				@window.window.move_resize(root_x - (@breadth - window_y), root_y - window_x, @breadth, length)
				@orientation = ORIENTATION_UP

			when ORIENTATION_UP
				@window.window.move_resize(root_x - window_y, root_y - (@breadth - window_x), length, @breadth)
				@orientation = ORIENTATION_LEFT
		end
		configure_orientation
	end

	###################################################################
	# Settings
	###################################################################
	def read_settings(settings)
		move( settings['ruler_x'], settings['ruler_y'] ) if settings['ruler_x']
		self.length = (settings['ruler_length'] || DEFAULT_RULER_LENGTH)
	end

	def write_settings(settings)
		settings['ruler_x'], settings['ruler_y'] = position
		settings['ruler_length'] = length
	end

private

	def configure_ppi
		@edge_size = 8
		@breadth = 35		# together with 'length', these are the two dimensions, independent of ruler rotation (whereas width=x, height=y)
	end

	def distance_from_zero(x, y)
		case @orientation
			when ORIENTATION_LEFT then x
			when ORIENTATION_UP		then y
		end
	end

	def configure_orientation		# make changes necessary for a new orientation
		case @orientation
			when ORIENTATION_LEFT
				@menu_box = Gdk::Rectangle.new(MENU_BOX_RELIEF, (@breadth / 2) - (MENU_BOX_HEIGHT / 2), MENU_BOX_WIDTH, MENU_BOX_HEIGHT)
				@near_edge, @far_edge = Gdk::Window::EDGE_WEST, Gdk::Window::EDGE_EAST

			when ORIENTATION_UP
				@menu_box = Gdk::Rectangle.new(MENU_BOX_RELIEF, (@breadth / 2) - (MENU_BOX_HEIGHT / 2), MENU_BOX_WIDTH, MENU_BOX_HEIGHT)
				@near_edge, @far_edge = Gdk::Window::EDGE_NORTH, Gdk::Window::EDGE_SOUTH
		end
		@window.set_size_request(@breadth, @breadth)
	end

	def mouse_is_in_window=(value)
		@mouse_is_in_window = value
		redraw
	end

	def grow(amount)	# can be negative
		case @orientation
			when ORIENTATION_LEFT then resize(@canvas.width + amount, @canvas.height)
			when ORIENTATION_UP then resize(@canvas.width, @canvas.height + amount)
		end
	end

	def prepare_rotated_canvas(cr)
		case @orientation
			when ORIENTATION_UP
				cr.translate(@breadth, 0)
				cr.rotate(Math::PI / 2)
		end
	end

	###################################################################
	# Drawing
	###################################################################
	def draw(cr)
		prepare_rotated_canvas(cr)
		pangolayout = cr.create_pango_layout.set_font_from_string($preferences_window.font)

		# Background
		cr.set_source_color($preferences_window.background_color)
		cr.rectangle(0, 0, length, @breadth)
		cr.fill

		# Foreground lines
		cr.set_source_color($preferences_window.foreground_color)
		cr.set_line_width(line_width_for_ppi)

		unit = @@unit_settings[$ruler_popup_menu.unit]

		# Two unit types require special code, as they are unrelated to inches
		case $ruler_popup_menu.unit
		when UNIT_PIXELS
			pixels_per_tick = 2
			units_per_pattern_repetition = unit.units_per_pattern_repetition
		when UNIT_PERCENTAGE
			# Change how many ticks we show, based on length of ruler
			ticks, units_per_pattern_repetition =	if length > 600 then [20, 10]
																						elsif length > 260 then [10, 20]
																						else [4, 50]
																						end
			pixels_per_tick = length.to_f / ticks.to_f
		else
			pixels_per_tick = (pixels_per_inch * unit.per_inch * unit.units_per_pattern_repetition) / unit.tick_pattern.size
			units_per_pattern_repetition = unit.units_per_pattern_repetition
		end

		# Loop, drawing ticks (top and bottom) and labels
		repetitions, tick_index = 0, 0
		loop(pixels_per_tick, length + OVERDRAW, pixels_per_tick) { |x|
			x = x.floor + 0.5		# Cairo likes lines in the 'center' of pixels

			tick_size = @@tick_sizes[ unit.tick_pattern[tick_index, 1].to_s ]

			# Top tick
			cr.move_to(x, 1.0)						# don't double-draw border pixel here...
			cr.line_to(x, tick_size)

			# Bottom tick
			cr.move_to(x, @breadth - tick_size)
			cr.line_to(x, @breadth - 1.0)	# ...not here either
			cr.stroke

			# Tick labels (once after each time we complete a tick_pattern)
			if tick_index == unit.tick_pattern.size - 1
				repetitions += 1
				pangolayout.text = sprintf("%d %s", repetitions * units_per_pattern_repetition, (repetitions == 1) ? unit.name : '')
				cr.show_pango_layout_centered(pangolayout, x, @breadth / 2)		# (see addons_gtk.rb)
			end

			tick_index = (tick_index + 1) % unit.tick_pattern.size	# tick_index repeats eg. 0->7 if there are 8 in the pattern
		}

		draw_mouse_tracker(cr) if @enable_mouse_tracking

		draw_menu_button(cr) if @mouse_is_in_window

		# Outline the ruler
		cr.rectangle(0.5, 0.5, length - 1.0, @breadth - 1.0)
		cr.stroke
	end

	def draw_mouse_tracker(cr)
		__window__unused__, mouse_x, mouse_y, key_mask = Gdk::Window.default_root_window.pointer

		tooltip_pango_layout = cr.create_pango_layout.set_font_from_string($preferences_window.font)

		window_x, window_y = position

		# Determine what measurement to show user
		progress_pixels = distance_from_zero((mouse_x - window_x), (mouse_y - window_y))
		progress_pixels = progress_pixels.clamp(0, length)

		tooltip_pango_layout.text = progress_pixels_to_unit_string(progress_pixels)
		tooltip_width, tooltip_height = tooltip_pango_layout.pixel_size

		case @orientation
			when ORIENTATION_LEFT
				tooltip_x = (mouse_x - window_x - (tooltip_width / 2.0)).clamp(@menu_box.x + @menu_box.width + @menu_box.x, (length - tooltip_width))
				tooltip_y = (@breadth - tooltip_height) / 2.0

			when ORIENTATION_UP
				tooltip_x = (mouse_y - window_y - (tooltip_width / 2.0)).clamp(@menu_box.x + @menu_box.width + @menu_box.x, (length - tooltip_width))
				tooltip_y = (@breadth - tooltip_height) / 2.0
		end

		# Cairo draws crisp lines when coordinates end in .5 (it's already either .0 or .5 due to division above)
		tooltip_x += 0.5 if (tooltip_x == tooltip_x.to_i)
		tooltip_y += 0.5 if (tooltip_y == tooltip_y.to_i)

		# Draw a line crossing the ruler at the measurement spot
		cr.set_source_color($preferences_window.foreground_color)
		cr.move_to(progress_pixels + 0.5, 0)
		cr.line_to(progress_pixels + 0.5, @breadth)
		cr.stroke

		# Fill a box with the background color
		cr.set_source_color($preferences_window.background_color)
		cr.rectangle(tooltip_x - 2.0, tooltip_y - 2.0, tooltip_width + 4.0, tooltip_height + 4.0)
		cr.fill_preserve		# (preserve so we can outline it below)

		# Draw outline around the box
		cr.set_source_color($preferences_window.foreground_color)
		cr.stroke

		# Draw measurement text
		cr.move_to(tooltip_x, tooltip_y)
		cr.show_pango_layout(tooltip_pango_layout)
	end

	def draw_menu_button(cr)
		# Outline
		cr.set_source_color($preferences_window.background_color)
		cr.rectangle(@menu_box.x + 0.5, @menu_box.y + 0.5, @menu_box.width, @menu_box.height)
		cr.fill_preserve

		# Fill with 'horizontal' lines
		cr.set_source_color($preferences_window.foreground_color)
		loop(@menu_box.y + 2.5, @menu_box.y + @menu_box.height + -1.5, 2) { |y|
			cr.move_to(@menu_box.x + 2.0, y)
			cr.line_to(@menu_box.x + @menu_box.width - 1, y)
		}
		cr.stroke
	end

	###################################################################
	# GTK Signal Handlers
	###################################################################
	def on_button_press_event(obj, event)
		case event.event_type
		when Gdk::Event::BUTTON_PRESS		# single-clicks
			case event.button
				when MOUSE_BUTTON_1		# popup, resize, or drag
					if menu_hit(event.x, event.y)
						$ruler_popup_menu.popup(event.x_root, event.y_root, event.x, event.y, event.time)
					elsif edge = edge_hit(event.x, event.y)
						begin_resize_drag(edge, event.button, event.x_root, event.y_root, event.time)
					else
						begin_move_drag(event.button, event.x_root, event.y_root, event.time)
					end

				when MOUSE_BUTTON_2		# middle-click = rotate ruler
					rotate(event.x_root, event.y_root, event.x, event.y)

				when MOUSE_BUTTON_3		# right-click anywhere = popup menu
					$ruler_popup_menu.popup(event.x_root, event.y_root, event.x, event.y, event.time)
			end
		when Gdk::Event::BUTTON2_PRESS		# double-click = preferences window
			$preferences_window.present
		end
	end

	def on_motion_notify_event(obj, event)
		if menu_hit(event.x, event.y)
			@window.window.cursor = Gdk::Cursor.new(Gdk::Cursor::HAND2)
		elsif edge = edge_hit(event.x, event.y)
			lookup = {	Gdk::Window::EDGE_NORTH => Gdk::Cursor::TOP_SIDE, Gdk::Window::EDGE_SOUTH => Gdk::Cursor::BOTTOM_SIDE,
									Gdk::Window::EDGE_WEST => Gdk::Cursor::LEFT_SIDE, Gdk::Window::EDGE_EAST => Gdk::Cursor::RIGHT_SIDE}
			@window.window.cursor = Gdk::Cursor.new(lookup[edge])
		else
			@window.window.cursor = Gdk::Cursor.new(Gdk::Cursor::FLEUR)
		end
	end

	def on_key_press_event(obj, event)
		move_distance	= (event.state.shift_mask?) ? MOVE_LARGE : MOVE_SMALL
		grow_amount		= (event.state.shift_mask?) ? GROW_LARGE : GROW_SMALL

		if event.state.mod1_mask?		# alt key
			case event.keyval
				when Gdk::Keyval::GDK_Right, Gdk::Keyval::GDK_Down then grow(grow_amount)
				when Gdk::Keyval::GDK_Left, Gdk::Keyval::GDK_Up then grow(-grow_amount)	# shrink ;)
				else return false		# not handled
			end
		else
			case event.keyval
				# quick-change unit measures
				when Gdk::Keyval::GDK_1 then $ruler_popup_menu.unit = UNIT_PIXELS
				when Gdk::Keyval::GDK_2 then $ruler_popup_menu.unit = UNIT_CENTIMETERS
				when Gdk::Keyval::GDK_3 then $ruler_popup_menu.unit = UNIT_INCHES
				when Gdk::Keyval::GDK_4 then $ruler_popup_menu.unit = UNIT_PICAS
				when Gdk::Keyval::GDK_5 then $ruler_popup_menu.unit = UNIT_POINTS
				when Gdk::Keyval::GDK_6 then $ruler_popup_menu.unit = UNIT_PERCENTAGE

				# move ruler by keyboard
				when Gdk::Keyval::GDK_Left	then offset(-move_distance, 0)
				when Gdk::Keyval::GDK_Right	then offset( move_distance, 0)
				when Gdk::Keyval::GDK_Up		then offset(0, -move_distance)
				when Gdk::Keyval::GDK_Down	then offset(0,  move_distance)

				# hide ruler
				when Gdk::Keyval::GDK_Escape then Gtk.main_quit

				# show menu via keyboard
				when Gdk::Keyval::GDK_Return												# popup menu (provide "click point" in case user chooses 'rotate')
					offset_x, offset_y = @breadth / 2, @breadth / 2		# provides a visually appealing rotation
					$ruler_popup_menu.popup(@window.position[0] + offset_x, @window.position[1] + offset_y, offset_x, offset_y, event.time)
				else return false		# not handled
			end
		end
		return true		# handled
	end

	###################################################################
	# Hit detection (menu button, edges)
	###################################################################
	def edge_hit(x, y)
		offset = distance_from_zero(x, y)
		if offset < @edge_size
			return @near_edge
		elsif offset > (length - @edge_size)
			return @far_edge
		else
			return nil
		end
	end

	def menu_hit(x, y)
		@menu_box.grow(2).contains(x,y)		# grow a little to be easier to click on
	end

	###################################################################
	# Utils
	###################################################################
	def line_width_for_ppi
		1.0	# TODO
	end

	def offset(x, y)
		move(position[0] + x, position[1] + y)
	end
end

# Local Variables:
# tab-width: 2
# End:
