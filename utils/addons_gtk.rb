 ###############################################################################
 #  Copyright 2008 Ian McIntosh <ian@openanswers.org>
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

# extend/simplify/standardize some GTK objects

#################################
# GTK classes
#################################

class Gtk::Window
	def toggle_visibility
		if active?		# is this window the current top level window on the current desktop?
			hide
		else
			present		 # show / move to current desktop / bring to top
		end
	end
end

class Gdk::Rectangle
	def grow(m)
		return Gdk::Rectangle.new(self.x - m, self.y - m, self.width + m*2, self.height + m*2)
	end

	def shrink(m)
		grow(-m)
	end

	def contains(x, y)
		return false if x < self.x
		return false if y < self.y
		return false if x > self.x + self.width
		return false if y > self.y + self.height
		return true
	end

	def center
		return [self.x + (self.width/2), self.y + (self.height/2)]
	end
end

class Gdk::Color
	def to_hex		# use Gdk::Color.parse to parse
		sprintf('#%02x%02x%02x', red / 257, green / 257, blue / 257)  # because 255 * 257 == 65535
	end
end

#################################
# other
#################################

class Cairo::Context
	def show_pango_layout_centered(pangolayout, x, y)
		w,h = pangolayout.pixel_size
		move_to(x - (w / 2), y - (h / 2))
		show_pango_layout(pangolayout)
	end
end

class Pango::Layout
	def set_font_from_string(str)
		set_font_description(Pango::FontDescription.new(str))
	end
end

class Gtk::Widget
	def on_key_press_event(event)
		modifiers = nil		# TODO: extract from event ?
		if @key_press_handlers and @key_press_handlers[modifiers] and @key_press_handlers[modifiers][event.keyval]
			@key_press_handlers[modifiers][event.keyval].each { |proc| proc.call(event) }
			true
		else
			false
		end
	end

	def on_key_press(keyval, modifiers = nil, &proc)
		if @key_press_handlers.nil?
			# On first use of on_key_press() setup GLib signal handler
			self.signal_connect('key-press-event') { |obj, event| on_key_press_event(event) }
			@key_press_handlers = {}
		end

		@key_press_handlers[modifiers] ||= {}
		@key_press_handlers[modifiers][keyval] ||= []
		@key_press_handlers[modifiers][keyval] << proc
	end
end

# Local Variables:
# tab-width: 2
# End:
