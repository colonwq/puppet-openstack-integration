#
# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Disable SSL (workaround for Xenial)
if $::operatingsystem == 'Ubuntu' {
  $ssl_enabled     = false
  $ipv6            = false
  # Watcher packages are not available in Ubuntu repository.
  $watcher_enabled = false
} else {
  $ssl_enabled     = true
  $ipv6            = false
  $watcher_enabled = true
}

include ::openstack_integration
class { '::openstack_integration::config':
  ssl  => $ssl_enabled,
  ipv6 => $ipv6,
}

class { '::openstack_integration::ceph':
  deploy_rgw   => false,
  swift_dropin => false,
}
