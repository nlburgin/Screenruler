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

require 'pathname'
require 'cairo'
require 'delegate'

class Canvas < DelegateClass(Gdk::Pixmap)	# so we can use Pixmap methods on our Canvas object
	attr_reader :widget, :height, :width

	def initialize
		@widget = Gtk::DrawingArea.new.show			# widget to draw on to
		@widget.double_buffered = false
		@redraw_needed = true

		# GTK Signal Handlers
		@widget.signal_connect('configure-event') { |obj, event|		# Widget changed size
			@width, @height = event.width, event.height		# save it
			@buffer = Gdk::Pixmap.new(@widget.window, @width, @height, @widget.window.depth)
			__setobj__(@buffer)	# set a new object to delegate to
			redraw
		}
		@widget.signal_connect('expose-event') { |obj, event|				# Widget changed visibility
			@gc ||= @widget.style.fg_gc(Gtk::STATE_NORMAL)
			@draw_proc.call(@buffer.create_cairo_context) if @redraw_needed
			@redraw_needed = false
			a = event.area ; @widget.window.draw_drawable(@gc, @buffer, a.x, a.y, a.x, a.y, a.width, a.height)
		}
		super(nil)	# 'nil' is the object to delegate to.  this is set later in 'configure-event' callback.
	end

	def set_draw_proc(&proc)
		@draw_proc = proc
		self
	end

	def redraw
		@redraw_needed = true
		@widget.queue_draw_area(0,0, @width, @height)
	end
end

# Local Variables:
# tab-width: 2
# End:
