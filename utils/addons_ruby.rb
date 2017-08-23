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

# extend/simplify/standardize some Ruby objects

class String
	def limit(max_length, indicator='...')
		return self[0, max_length] + indicator if length > max_length
		return self
	end
end

class Dir
	def each_matching(pattern)	# patterns like '*.png'
		each { |filename|	yield filename if File.fnmatch(pattern, filename) }
	end
end

class Numeric
	def clamp(low, high)
		return low if self <= low
		return high if self >= high
		return self
	end
end

class Fixnum
	def within?(low, high)
		return (to_i >= low and to_i <= high)
	end
end

class Object
	def to_a
		return self if is_a?(Array)
		return [self]
	end
end

module Kernel
	# a new 'require' supporting multiple files
	alias_method :orig_require, :require
	def require(*list)
		list.each { |file| orig_require(file) }
	end

	def loop(from, to, step=1)
		i = from
		while i <= to
			yield i
			i += step
		end
	end
end

# Local Variables:
# tab-width: 2
# End:
