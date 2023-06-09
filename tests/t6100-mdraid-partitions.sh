#!/bin/sh
# verify that new kernel is informed about partitions on mdraid devices

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

. "${srcdir=.}/init.sh"; path_prepend_ ../parted

require_root_
require_scsi_debug_module_
require_mdadm_

# create memory-backed device
scsi_debug_setup_ dev_size_mb=10 > dev-name ||
  skip_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

# Arbitrary number, not likely to be used already
md_name=md99
md_dev=/dev/$md_name

test -b $md_dev && skip_ "$md_dev already exists"

# Use gpt and create two partitions on the device.
parted -s "$scsi_dev" mklabel gpt \
    mkpart p1 ext2 1M 4M \
    mkpart p2 ext2 5M 8M > out 2>&1 || fail=1
compare /dev/null out || fail=1
wait_for_dev_to_appear_ ${scsi_dev}2 || { fail=1; cat /proc/partitions; }

cleanup_fn_() {
  # stop mdraid array
  mdadm -S $md_dev || warn_ "Failed to stop MD array, $md_dev"
}

# create mdraid on top of both partitions with v0.90 metadata
mdadm -C $md_dev -e0 --force -R -l1 -n2 "${scsi_dev}1" "${scsi_dev}2"
wait_for_dev_to_appear_ ${md_dev} || { fail=1; cat /proc/partitions; }

# create gpt and two partitions on the raid device
parted -s $md_dev mklabel gpt \
    mkpart r1 ext2 1M 2M \
    mkpart r2 ext2 2M 3M > out 2>&1 || fail=1
compare /dev/null out || fail=1

# Verify that kernel has been informed about the second device.
wait_for_dev_to_appear_ ${md_dev}p2 || { fail=1; cat /proc/partitions; }

# Remove partitions from the raid device.
parted -s $md_dev rm 2 rm 1 > out 2>&1 || fail=1
compare /dev/null out || fail=1

# Verify that kernel has been informed about those removals.
wait_for_dev_to_disappear_ ${md_dev}p1 2 || { fail=1; cat /proc/partitions; }
wait_for_dev_to_disappear_ ${md_dev}p2 2 || { fail=1; cat /proc/partitions; }

Exit $fail
