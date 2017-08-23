#!/usr/bin/ruby22
#coding: utf-8

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

Dir.chdir(File.dirname(File.expand_path(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)))		# So that this file can be run from anywhere
$LOAD_PATH << './utils'

require 'gettext'		# Internationalization Support
include GetText
bindtextdomain("screenruler", :path => "locale")

###################################################################
# Constants
###################################################################
UNIT_PIXELS, UNIT_CENTIMETERS, UNIT_INCHES, UNIT_PICAS, UNIT_POINTS, UNIT_PERCENTAGE = (0..5).to_a
UNIT_LAST = UNIT_PERCENTAGE

APP_NAME					= _('Screen Ruler')
APP_COPYRIGHT			= "Copyright (c) #{Time.now.year} Ian McIntosh"
APP_AUTHORS 			= ['Ian McIntosh <ian@openanswers.org>']
APP_ARTISTS				= ['János Horváth <horvathhans@gmail.com>']
APP_VERSION				= '0.9.6'
APP_LOGO_FILENAME = 'screenruler-logo.png'

SETTINGS_SUBDIRECTORY_NAME = 'screenruler'
SETTINGS_FILE_NAME = 'settings.yml'

###################################################################
# Includes
###################################################################
puts _('Loading libraries...')

require 'addons_ruby'									# for multi-file 'require'
require 'gtk2', 'settings', 'addons_gtk'
require_relative 'ruler_window'
require_relative 'preferences_window'
require_relative 'help_window'
###################################################################
# Main
###################################################################
Gtk.init

APP_ICON_LIST = ['screenruler-icon-16x16.png', 'screenruler-icon-32x32.png', 'screenruler-icon-64x64.png'].collect { |filename| Gdk::Pixbuf.new(filename) }

#
# Load Settings
#
settings_directory = File.join(GLib.user_config_dir, SETTINGS_SUBDIRECTORY_NAME)
Dir.mkdir(GLib.user_config_dir) rescue nil ; Dir.mkdir(settings_directory) rescue nil
settings_file_path = File.join(settings_directory, SETTINGS_FILE_NAME)
settings = Settings.new.load(settings_file_path)

#
# Startup
#
puts _('Creating windows...')
	$preferences_window = PreferencesWindow.new
	$ruler_window = RulerWindow.new
	$ruler_popup_menu = RulerPopupMenu.new
	$help_window = HelpWindow.new

puts _('Reading settings...')
	$preferences_window.read_settings(settings)
	$ruler_window.read_settings(settings)
	$ruler_popup_menu.read_settings(settings)

puts _('Presenting ruler...')
	$ruler_window.present

begin
	Gtk.main
ensure
	puts _('Shutting down...')
	[$ruler_window, $ruler_popup_menu, $preferences_window].each { |win| win.hide }				# feels snappy
	[$ruler_window, $ruler_popup_menu, $preferences_window].each { |win| win.write_settings(settings) }
	settings.save(settings_file_path)
end

# Local Variables:
# tab-width: 2
# End:
