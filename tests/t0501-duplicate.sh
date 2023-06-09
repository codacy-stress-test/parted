#!/bin/sh
# Drive the dup-clobber program.

# Copyright (C) 2011-2014, 2019-2023 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

. "${srcdir=.}/init.sh"; path_prepend_ ../parted .

for t in msdos gpt bsd sun atari mac pc98; do
    case $t in
      atari) [ $ss -ne 512 ] && continue
          ;;
      *) duplicate $t || fail=1
          ;;
    esac
done

Exit $fail
