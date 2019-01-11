#!/usr/bin/env bash
set -e

# Arch Linux Install Script (alis)
# Copyright (C) 2019 aramcap (https://github.com/aramcap/alis)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

rm -f alis.conf
rm -f alis.sh
wget https://raw.githubusercontent.com/aramcap/alis/master/alis.conf
wget https://raw.githubusercontent.com/aramcap/alis/master/alis.sh

vim alis.conf
bash alis.sh