 ###############################################################################
 #  Copyright 2006 Ian McIntosh <ian@openanswers.org>
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

# UniqueTimeoutCallback will call the provided block ONCE after the given delay.
# If 'set' is called again, it will cancel the previous callback.

class UniqueTimeout
	def initialize(time_in_millisecond, &proc)
		@time = time_in_millisecond.to_f
		@proc = proc
	end

	def start
		stop
		@callback_id = Gtk.timeout_add(@time) { ret = @proc.call ; true }		# true = don't call again
	end

	def stop
		Gtk.timeout_remove(@callback_id) if @callback_id
		@callback_id = nil
	end
end
