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

class HelpWindow < GladeWindow
	def initialize
		super('help_window')
		@window.signal_connect('delete_event') { hide }
		on_key_press(Gdk::Keyval::GDK_Escape) { hide }
	end

	def on_close_button_clicked
		hide
	end
end

# Local Variables:
# tab-width: 2
# End:
