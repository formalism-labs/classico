
from __future__ import absolute_import
import platform
import os
import re
from subprocess import Popen, PIPE
from typing import Optional

from .platform_base import *
from .text import match, is_numeric
from .files import fread
from .error import Error
from .error import *
from .range_dict import *

#----------------------------------------------------------------------------------------------

OSNICKS = {
    "questing": { "docker": "ubuntu:questing" },
    "plucky":   { "docker": "ubuntu:plucky" },
    "oracular": { "docker": "ubuntu:oracular" },
	"noble":    { "docker": "ubuntu:noble" },
	"jammy":    { "docker": "ubuntu:jammy" },
	"lunar":    { "docker": "ubuntu:lunar" },
	"kinetic":  { "docker": "ubuntu:kinetic" },
	"hirsute":  { "docker": "ubuntu:hirsute" },
	"focal":    { "docker": "ubuntu:focal" },
	"bionic":   { "docker": "ubuntu:bionic" },
	"xenial":   { "docker": "ubuntu:xenial" },
	"trusty":   { "docker": "ubuntu:trusty" },

	"sid":      { "docker": "debian:sid" },
	"bookworm": { "docker": "debian:bookworm" },
	"bullseye": { "docker": "debian:bullseye-slim" },
	"buster":   { "docker": "debian:buster-slim" },
	"stretch":  { "docker": "debian:stretch" },

	"leap":       { "docker": "opensuse/leap:latest" },
	"leap15":     { "docker": "opensuse/leap:15" },
	"leap15.6":   { "docker": "opensuse/leap:15.6" },
	"tumbleweed": { "docker": "opensuse/tumbleweed" },

	"arch":      { "docker": "archlinux:latest" },
	"archlinux": { "docker": "archlinux:latest" },
	"manjaro":   { "docker": "manjarolinux/base:latest" },

	"alpine3": { "docker": "alpine:latest" },

	"fedora":   { "docker": "fedora:latest" },
	"fedora42": { "docker": "fedora:42" },
	"fedora41": { "docker": "fedora:41" },
	"rawhide":  { "docker": "fedora:rawhide" },

	"centos7":  { "docker": "centos:7" },
	"centos8":  { "docker": "quay.io/centos/centos:stream8" },
	"centos9":  { "docker": "quay.io/centos/centos:stream9" },
	"centos10": { "docker": "quay.io/centos/centos:stream10" },
	"ol7": { "docker": "oraclelinux:7" },
	"ol8": { "docker": "oraclelinux:8" },
	"ol9": { "docker": "oraclelinux:9" },
	"alma8":  { "docker": "almalinux:8" },
	"alma9":  { "docker": "almalinux:9" },
	"alma10": { "docker": "almalinux:10" },
	"rocky8": { "docker": "rockylinux:8" },
	"rocky9": { "docker": "rockylinux:9" },
	"rocky10": { "docker": "rockylinux:10" },
	"rhel9":  { "docker": "redhat/ubi9:latest" },
	"rhel10": { "docker": "redhat/ubi10:latest" },
	"amzn2":  { "docker": "amazonlinux:2" },
	"amzn22": { "docker": "amazonlinux:2022" },
	"amzn23": { "docker": "amazonlinux:2023" },
	"mariner2":    { "docker": "mcr.microsoft.com/cbl-mariner/base/core:2.0" },
	"azurelinux3": { "docker": "mcr.microsoft.com/azurelinux/base/core:3.0" },

    "cheetah":      { 'macos': True },
    "puma":         { 'macos': True },
    "jaguar":       { 'macos': True },
    "panther":      { 'macos': True },
    "tiger":        { 'macos': True },
    "leopard":      { 'macos': True },
    "snowleopard":  { 'macos': True },
    "lion":         { 'macos': True },
    "mountainlion": { 'macos': True },
    "mavericks":    { 'macos': True },
    "yosemite":     { 'macos': True },
    "elcapitan":    { 'macos': True },
    "sierra":       { 'macos': True },
    "highsierra":   { 'macos': True },
    "mojave":       { 'macos': True },
    "catalina":     { 'macos': True },
    "bigsur":       { 'macos': True },
    "monterey":     { 'macos': True },
    "ventura":      { 'macos': True },
    "sonoma":       { 'macos': True },
    "sequoia":      { 'macos': True },
    "tahoe":        { 'macos': True },

    "win-g0":  { 'windows': True }, # <xp, <s2003
    "win-g5":  { 'windows': True }, # xp, s2003
    "win-g7":  { 'windows': True }, # 7.1, s2008r2
    "win-g8":  { 'windows': True }, # 8.1, s2022r2
    "win-g10": { 'windows': True }, # 10, s2016-22
    "win-g11": { 'windows': True }, # 11, s2025

    "windows-xp": { 'windows': True },
    "windows-7":  { 'windows': True },
    "windows-8":  { 'windows': True },
    "windows-10": { 'windows': True },
    "windows-11": { 'windows': True },

    "windows-server-2000":    { 'windows': True },
    "windows-server-2003":    { 'windows': True },
    "windows-server-2008-r2": { 'windows': True },
    "windows-server-2012":    { 'windows': True },
    "windows-server-2016":    { 'windows': True },
    "windows-server-2019":    { 'windows': True },
    "windows-server-2022":    { 'windows': True },
    "windows-server-2025":    { 'windows': True },
}

#----------------------------------------------------------------------------------------------

DEBIAN_VERSIONS = {
    'buzz':      '1.1',
    'rex':       '1.2',
    'bo':        '1.3',
    'hamm':      '2.0',
    'slink':     '2.1',
    'potato':    '2.2',
    'woody':     '3.0',
    'sarge':     '3.1',
    'etch':      '4.0',
    'lenny':     '5.0',
    'squeeze':   '6.0',
    'wheezy':    '7',
    'jessie':    '8',
    'stretch':   '9',
    'buster':   '10',
    'bullseye': '11',
    'bookworm': '12',
    'trixie':   '13',
    'forky':    '14',
}

UBUNTU_VERSIONS = {
    'trusty':   '14.04',
    'xenial':   '16.04',
    'bionic':   '18.04',
    'disco':    '19.04',
    'eoan':     '19.10',
    'focal':    '20.04',
    'groovy':   '20.10',
    'hirsute':  '21.04',
    'impish':   '21.10',
    'jammy':    '22.04',
    'kinetic':  '22.10',
    'lunar':    '23.04',
    'mantic':   '23.10',
    'noble':    '24.04',
    'oracular': '24.10',
    'plucky':   '25.04',
    'questing': '25.10',
}

#----------------------------------------------------------------------------------------------

MACOS_VERSIONS = {
    "cheetah":      "10.0",
    "puma":         "10.1",
    "jaguar":       "10.2",
    "panther":      "10.3",
    "tiger":        "10.4",
    "leopard":      "10.5",
    "snowleopard":  "10.6",
    "lion":         "10.7",
    "mountainlion": "10.8",
    "mavericks":    "10.9",
    "yosemite":     "10.10",
    "elcapitan":    "10.11",
    "sierra":       "10.12",
    "highsierra":   "10.13",
    "mojave":       "10.14",
    "catalina":     "10.15",
    "bigsur":       "11",
    "monterey":     "12",
    "ventura":      "13",
    "sonoma":       "14",
    "sequoia":      "15",
    "tahoe":        "26",
}

DARWIN_VERSIONS = {
    "cheetah":      "1.3",
    "puma":         "1.4",
    "jaguar":       "6",
    "panther":      "7",
    "tiger":        "8",
    "leopard":      "9",
    "snowleopard":  "10",
    "lion":         "11",
    "mountainlion": "12",
    "mavericks":    "13",
    "yosemite":     "14",
    "elcapitan":    "15",
    "sierra":       "16",
    "highsierra":   "17",
    "mojave":       "18",
    "catalina":     "19",
    "bigsur":       "20",
    "monterey":     "21",
    "ventura":      "22",
    "sonoma":       "23",
    "sequoia":      "24",
    "tahoe":        "25",
}

MACOS_VERSIONS_NICKS = {v: k for k, v in MACOS_VERSIONS.items()}
DARWIN_VERSIONS_NICKS = {v: k for k, v in DARWIN_VERSIONS.items()}

#----------------------------------------------------------------------------------------------

WINDOWS_BUILDS = RangeDict({
     2125:  { "version": "2000",  "internal": "5.0",  "code": "" },
     2600:  { "version": "xp",    "internal": "5.1",  "code": "" },
     3790:  { "version": "xp",    "internal": "5.2",  "code": "" },
    (6000,
     6003): { "version": "vista", "internal": "6.0",  "code": "" },
     7600:  { "version": "7",     "internal": "6.1",  "code": "" },
     7601:  { "version": "7-sp1", "internal": "6.1",  "code": "" },
     9200:  { "version": "8",     "internal": "6.2",  "code": "" },
     9600:  { "version": "8.1",   "internal": "6.3",  "code": "" },
    10240:  { "version": "10",    "internal": "10.0", "code": "1507" },
    10586:  { "version": "10",    "internal": "10.0", "code": "1511" },
    14393:  { "version": "10",    "internal": "10.0", "code": "1607" },
    15063:  { "version": "10",    "internal": "10.0", "code": "1703" },
    16299:  { "version": "10",    "internal": "10.0", "code": "1709" },
    17134:  { "version": "10",    "internal": "10.0", "code": "1803" },
    17763:  { "version": "10",    "internal": "10.0", "code": "1809" },
    18362:  { "version": "10",    "internal": "10.0", "code": "1903" },
    18363:  { "version": "10",    "internal": "10.0", "code": "1909" },
    19041:  { "version": "10",    "internal": "10.0", "code": "2004" },
    19042:  { "version": "10",    "internal": "10.0", "code": "20H2" },
    19043:  { "version": "10",    "internal": "10.0", "code": "21H1" },
    19044:  { "version": "10",    "internal": "10.0", "code": "21H2" },
    19045:  { "version": "10",    "internal": "10.0", "code": "22H2" },
    22000:  { "version": "11",    "internal": "10.0", "code": "21H2" },
    22621:  { "version": "11",    "internal": "10.0", "code": "22H2" },
    22631:  { "version": "11",    "internal": "10.0", "code": "23H2" },
    26100:  { "version": "11",    "internal": "10.0", "code": "24H2" },
    26200:  { "version": "11",    "internal": "10.0", "code": "25H2" },
    27928:  { "version": "11",    "internal": "10.0", "code": "25H2" }, # canary
    })

WINDOWS_SERVER_BUILDS = RangeDict({
      2125:  { "version": "2000",        "internal": "5.0",  "code": "" },
      3790:  { "version": "2003",        "internal": "5.2",  "code": "" },
     (6000,
      6003): { "version": "2008",        "internal": "6.0",  "code": "" },
      7600:  { "version": "2008-r2",     "internal": "6.1",  "code": "" },
      7601:  { "version": "2008-r2-sp1", "internal": "6.1",  "code": "" },
      9200:  { "version": "2012",        "internal": "6.2",  "code": "" },
      9600:  { "version": "2012-r2",     "internal": "6.3",  "code": "" },
     14393:  { "version": "2016",        "internal": "10.0", "code": "1607" },
     16299:  { "version": "sac-1709",    "internal": "10.0", "code": "1709" },
     17134:  { "version": "sac-1803",    "internal": "10.0", "code": "1803" },
     17763:  { "version": "2019",        "internal": "10.0", "code": "1809" },
     18362:  { "version": "sac-1903",    "internal": "10.0", "code": "1903" },
     19041:  { "version": "sac-2004",    "internal": "10.0", "code": "2004" },
     19042:  { "version": "sac-20H2",    "internal": "10.0", "code": "20H2" },
     20348:  { "version": "2022-ltsc",   "internal": "10.0", "code": "21H2" },
     22621:  { "version": "2025",        "internal": "10.0", "code": "22H2" },
     22631:  { "version": "2025",        "internal": "10.0", "code": "23H2" },
    (26100,
     26404): { "version": "2025",        "internal": "10.0", "code": "24H2" },
    })

#----------------------------------------------------------------------------------------------

# note that this also applies to Msys2 and Cygwin

class OSRelease:
    CUSTOM_BRANDS = [ 'elementary', 'pop' ] # , 'rocky', 'almalinux'
    UBUNTU_BRANDS = [ 'elementary', 'pop' ]
    RHEL_BRANDS = [ 'centos', 'rhel', 'redhat', 'rocky', 'almalinux' ]
    ROLLING_BRANDS = [ 'arch', 'gentoo', 'manjaro' ]

    def __init__(self, brand=False):
        self.defs = {}
        self.brand_mode = brand
        with open("/etc/os-release") as f:
            for line in f:
                try:
                    k, v = line.rstrip().split("=")
                    self.defs[k] = v.strip('"').strip("'")
                except:
                    pass

    def __repr__(self):
        return str(self.defs)

    #--------------------------------------------------------------------------------------

    # e.g. "centos", "fedora", "rhel", "ubuntu", "debian"
    def id(self):
        if self.is_custom_brand() and not self.brand_mode:
            like = self.id_like()
            return like[0]
        return self.defs.get("ID", "")

    # possibly list of values, e.g. "rhel centos fedora"
    def id_like(self):
        return self.defs.get("ID_LIKE", "").split()

    def version_id(self):
        brand = self.brand_id()
        if brand in self.ROLLING_BRANDS:
            return "rolling"

        if brand in self.UBUNTU_BRANDS:
            ver_id = UBUNTU_VERSIONS.get(self.ubuntu_codename(), "")
            if ver_id == "":
                raise Error("Cannot determine os version")
            return ver_id

        if brand in self.RHEL_BRANDS:
            ver = self.defs.get("VERSION_ID", "").split('.')
            return ver[0]

        ver = self.defs.get("VERSION_ID", "")
        if ver == "" and self.id() == 'debian':
            ver, _ = self.debian_sid_version()
        return ver

    def debian_sid_version(self):  # returns version_id, codename
        m = match(r'Debian GNU/Linux ([^/]+)/sid', self.pretty_name())
        if m:
            return DEBIAN_VERSIONS.get(m[1], ""), m[1]
        else:
            return "", ""

    # e.g. "bionic", "focal", "jammy" - not always present
    def version_codename(self):
        brand = self.brand_id()
        if brand in self.UBUNTU_BRANDS:
            return self.ubuntu_codename()
        codename = self.defs.get("VERSION_CODENAME", "")
        if codename == "" and self.id() == 'debian':
            _, codename = self.debian_sid_version()
        return codename

    #--------------------------------------------------------------------------------------

    def variant_id(self):
        # fedora-specific
        return self.defs.get("VARIANT_ID")

    # e.g. "bionic", "focal", "jammy"
    def ubuntu_codename(self):
        # ubuntu-specific
        return self.defs.get("UBUNTU_CODENAME")

    #--------------------------------------------------------------------------------------

    def name(self):
        return self.defs.get("NAME", "")

    def pretty_name(self):
        return self.defs.get("PRETTY_NAME", "")

    def version(self):
        # text
        return self.defs.get("VERSION", "")

    #--------------------------------------------------------------------------------------

    def brand_id(self):
        return self.defs.get("ID", "")

    def brand_codename(self):
        return self.defs.get("VERSION_CODENAME", "")

    def brand_version_id(self):
        return self.defs.get("VERSION_ID", "")

    def is_custom_brand(self):
        id = self.brand_id()
        return id != "" and id in self.CUSTOM_BRANDS

#----------------------------------------------------------------------------------------------

class LinuxDist:
    def __init__(self, os_release: OSRelease, brand_mode=False, strict=False):
        dist = os_release.id()
        if dist == 'fedora' or dist == 'debian':
            pass
        elif dist == 'ubuntu':
            pass
        elif dist == 'mariner':
            pass
        elif dist == 'azurelinux':
            pass
        elif dist.startswith('rocky') or dist.startswith('almalinux') or dist.startswith('redhat') or dist == 'rhel':
            if not brand_mode:
                dist = 'centos'
        elif dist.startswith('suse'):
            dist = 'suse'
        elif dist.startswith('amzn'):
            dist = 'amzn'
        else:
            if 'arch' in os_release.id_like():
                dist = 'arch'
            if strict:
                raise Error("Cannot determine distribution")
            elif dist == '':
                dist = 'unknown'
        self._dist = dist

    def __str__(self):
        return self._dist

    def __repr__(self):
        return f"Dist({self._dist})"

    def __eq__(self, other):
        if isinstance(other, LinuxDist):
            return self._dist == other._dist
        if isinstance(other, str):
            return self._dist == other
        return False

    def __hash__(self):
        return hash(self._dist)

#----------------------------------------------------------------------------------------------

class OSNick:
    _osnick: str

    def __init__(self, nick: Optional[str] = None):
        try:
            if nick is None:
                self._osnick = str(Platform().osnick)
                return
            _ = OSNICKS[nick]  # noqa: F841
            self._osnick = nick
        except:
            raise Error(f"invalid osnick: {nick}")

    @classmethod
    def from_host(cls):
        self = super().__new__(cls)
        self._osnick = Platform().osnick
        return self
    
    @classmethod
    def from_linux(cls, linux_dist: LinuxDist, os_release: OSRelease):
        self = super().__new__(cls)
        osnick = None
        dist = str(linux_dist)
        if dist == 'ubuntu' or dist == 'debian':
            osnick = os_release.version_codename()
            if osnick == "":
                versions = DEBIAN_VERSIONS if dist == 'debian' else UBUNTU_VERSIONS
                versions_nicks = {v: k for k, v in versions.items()}
                osnick = versions_nicks.get(os_release.version_id(), "")
            if osnick == 'ubuntu14.04':
                osnick = 'trusty'
        elif dist == 'arch':
            osnick = dist
        elif dist == 'ol':
            osnick = dist + str(os_release.version_id().split('.')[0])
        if osnick is None:
            osnick = dist + str(os_release.version_id())
        self._osnick = osnick
        return self

    @classmethod
    def from_macos(cls, darwin_ver: str, macos: str, macos_ver: str):
        self = super().__new__(cls)
        self._osnick = DARWIN_VERSIONS_NICKS.get(darwin_ver.split('.')[0], macos + str(macos_ver))
        return self

    @classmethod
    def from_windows(cls, ostype: str, os_ver: str):
        self = super().__new__(cls)
        self._osnick = f"{ostype}-{os_ver}"
        return self

    @classmethod
    def from_freebsd(cls, _os: str, os_ver: str):
        self = super().__new__(cls)
        self._osnick = _os + os_ver
        return self

    @classmethod
    def from_solaris(cls, _os: str, os_ver: str):
        self = super().__new__(cls)
        self._osnick = _os + os_ver
        return self

    def __str__(self):
        return self._osnick

    def __repr__(self):
        return f"OSNick({self._osnick})"

    def __eq__(self, other):
        if isinstance(other, OSNick):
            return self._osnick == other._osnick
        if isinstance(other, str):
            return self._osnick == other
        return False

    def __hash__(self):
        return hash(self._osnick)
    
    def docker_image(self):
        try:
            return OSNICKS[self._osnick]["docker"]
        except:
            raise Error("invalid osnick ({self._osnick}) or missing docker image")

#----------------------------------------------------------------------------------------------

class Platform:
    os: str
    strict: bool
    brand_mode: bool
    dist: str
    shell: str
    linux_dist: Optional[LinuxDist] = None
    osnick: OSNick
    os_ver: str
    os_full_ver: str
    arch: str
    
    def __init__(self, strict=False, brand=False):
        self.os = self.dist = self.os_ver = self.os_full_ver = self.osnick = self.arch = '?'
        self.strict = strict
        self.brand_mode = brand

        self.os = platform.system().lower()  # this would be later modify by _identify methods
        if self.os == 'linux':
            self._identify_linux()
        elif self.os == 'darwin':
            self._identify_macos()
        elif self.os == 'windows':
            self._identify_windows()
        elif self.os == 'sunos':
            self._identify_solaris()
        elif self.os == 'freebsd':
            self._identify_freebsd()
        else:
            if strict:
                raise Error("Cannot determine OS")
            self.os_ver = ''
            self.dist = ''

        self.arch = platform_arch()
        # self._identify_arch()

    #------------------------------------------------------------------------------------------

    def _identify_linux(self):
        try:
            os_release = OSRelease(brand=self.brand_mode)
            self.os_ver = os_release.version_id()
            self.linux_dist = LinuxDist(os_release, self.brand_mode, self.strict)
            self.dist = str(self.linux_dist)
            self.osnick = OSNick.from_linux(self.linux_dist, os_release)
            self.os_full_ver = self._identify_linux_full_ver(os_release, self.dist)
        except:
            if self.strict:
                raise Error("Cannot determine distribution")
            self.os_ver = self.os_full_ver = 'unknown'

    def _identify_linux_full_ver(self, os_release, dist):
        if dist in OSRelease.RHEL_BRANDS + ['ol']:
            redhat_release = fread('/etc/redhat-release')
            m = match(r'.* release ([^\s]+)', redhat_release)
            if m:
                fullver = m[1]
                return fullver
        elif dist == 'ubuntu':
            brand = os_release.brand_id()
            if brand in os_release.UBUNTU_BRANDS:
                return self.os_ver
            m = match(r'([^\s]+)', os_release.version())
            if m:
                return m[1]
        return os_release.version_id()

    #------------------------------------------------------------------------------------------

    def _identify_macos(self):
        self.os = 'macos'
        self.dist = ''
        mac_ver = platform.mac_ver()
        self.os_full_ver = mac_ver[0] # e.g. 10.14, but also 10.5.8
        self.os_ver = '.'.join(self.os_full_ver.split('.')[:2]) # major.minor
        darwin_ver = sh("uname -r")
        self.osnick = OSNick.from_macos(darwin_ver, self.os, self.os_ver)
        # self.arch = mac_ver[2] # e.g. x64_64

    def _identify_windows(self):
        self.shell = platform_shell()
        
        self.os_full_ver = platform.version()
        self.os_ver = self.os_full_ver
        v = self.os_ver.split(".")
        # major = v[0]
        build = int(v[2])

        dist = sh("regtool get '/HKLM/SOFTWARE/Microsoft/Windows NT/CurrentVersion/InstallationType'")
        if dist == 'Client':
            self.dist = "windows"
        elif dist == 'Server':
            self.dist = "windows-server"
        elif dist == 'Server Core':
            self.dist = "windows-server-core"

        builds_dict = WINDOWS_BUILDS if self.dist == "windows" else WINDOWS_SERVER_BUILDS
        if build in builds_dict:
            build_info = builds_dict[build]
        else:
            last_build = 0
            for rng in builds_dict:
                if rnd.end > build:
                    break
                last_build = rng.start
            if last_build > 0:
                last_build = list(builds_dict.keys())[-1][1]
            build_info = builds_dict[last_build]

        self.os_ver = build_info['version']
        self.osnick = OSNick.from_windows(self.dist, self.os_ver)
        self.build = build

    def _identify_freebsd(self):
        self.dist = ''
        ver = sh('freebsd-version')
        m = match(r'([^-]*)-(.*)', ver)
        self.os_ver = self.os_full_ver = m[1]
        self.osnick = OSNick.from_freebsd(self.os, self.os_ver)

    def _identify_solaris(self):
        self.os = 'solaris'
        self.os_ver = ''
        self.dist = ''
        self.osnick = OSNick.from_solaris(self.os, self.os_ver)

    #------------------------------------------------------------------------------------------

    def _identify_arch(self):
        self.arch = platform.machine().lower()
        if self.arch == 'amd64' or self.arch == 'x86_64':
            self.arch = 'x64'
        elif self.arch == 'i386' or self.arch == 'i686' or self.arch == 'i86pc':
            self.arch = 'x86'
        elif self.arch == 'aarch64' or self.arch == 'arm64':
            self.arch = 'arm64v8'
        elif self.arch == 'armv7l':
            self.arch = 'arm32v7'
        elif self.arch == 's390x':
            pass

    #------------------------------------------------------------------------------------------

    def triplet(self):
        return '-'.join([self.os, str(self.osnick), self.arch])

    @property
    def os_version(self):
        return tuple(map(lambda x: int(x) if is_numeric(x) else x, self.os_full_ver.split('.')))

    #------------------------------------------------------------------------------------------

    def is_debian_compat(self):
        return self.dist in ['debian', 'ubuntu', 'linuxmint', 'raspbian']

    def is_redhat_compat(self):
        return self.dist in ['redhat', 'rhel', 'centos', 'rocky', 'alma', 'almalinux', 'amzn', 'ol']

    def redhat_compat_version(self):
        if self.dist in ['redhat', 'rhel', 'centos', 'rocky', 'alma', 'almalinux', 'ol']:
            return self.os_version[0]
        elif self.dist == 'amzn':
            amzn_vers = { 2: 7, 2022: 8, 2023: 9 }
            try:
                return amzn_vers[self.os_version[0]]
            except:
                raise Error("unknown amazonlinux version")
        else:
            raise Error("unknown RHEL version")

    def is_arch_compat(self):
        return self.dist in ['arch', 'manjaro']

    def is_arm(self):
        return self.arch == 'arm64v8' or self.arch == 'arm32v7'

    def is_arm64(self):
        return self.arch == 'arm64v8'

    def is_container(self):
        with open('/proc/1/cgroup', 'r') as conf:
            for line in conf:
                if re.search('docker', line):
                    return True
        return False

    #------------------------------------------------------------------------------------------

    def report(self):
        if self.dist != "":
            _os = self.dist + " " + self.os
        else:
            _os = self.os
        if self.osnick != "":
            nick = " (" + str(self.osnick) + ")"
        else:
            nick = ""
        print(_os + " " + self.os_ver + nick + " " + self.arch)

#----------------------------------------------------------------------------------------------

class OnPlatform:
    def __init__(self):
        self.stages = [0]
        self.platform = Platform()

    def invoke(self):
        _os = self.os = self.platform.os
        dist = self.dist = self.platform.dist
        self.ver = self.platform.os_ver
        self.common_first()

        for stage in self.stages:
            self.stage = stage
            self.common()
            if _os == 'linux':
                self.linux_first()
                self.linux()

                if self.platform.is_debian_compat():
                    self.debian_compat()
                if self.platform.is_redhat_compat():
                    self.redhat_compat()
                if self.platform.is_arch_compat():
                    self.archlinux()

                if dist == 'fedora':
                    self.fedora()
                elif dist == 'ubuntu':
                    self.ubuntu()
                elif dist == 'debian':
                    self.debian()
                elif dist in ['centos', 'rocky', 'alma', 'redhat', 'rhel']:
                    self.centos()
                elif dist in ['redhat', 'rhel']:
                    self.redhat()
                elif dist == 'arch':
                    pass
                elif dist == 'ol':
                    self.oracle()
                elif dist == 'suse':
                    self.suse()
                elif dist == 'linuxmint':
                    self.linuxmint()
                elif dist == 'amzn':
                    self.amzn()
                elif dist == 'alpine':
                    self.alpine()
                elif dist == 'raspbian':
                    self.raspbian()
                elif dist == 'mariner':
                    self.mariner()
                elif dist == 'azurelinux':
                    self.azurelinux()
                else:
                    assert(False), "Cannot determine installer"

                self.linux_last()
            elif _os == 'macos' or os == 'macos':
                self.macos()
            elif _os == 'freebsd':
                self.freebsd()
            elif _os == 'windows':
                shell = self.platform.dist
                if shell == 'msys2':
                    self.msys2()
                elif shell == 'cygwin':
                    self.cygwin()
                self.windows()

        self.common_last()

    def common(self):
        pass

    def common_first(self):
        pass

    def common_last(self):
        pass

    def linux(self):
        pass

    def linux_first(self):
        pass

    def linux_last(self):
        pass

    def archlinux(self):
        pass

    def debian_compat(self): # debian, ubuntu, etc
        pass

    def debian(self):
        pass

    def centos(self):
        pass

    def oracle(self):
        pass

    def fedora(self):
        pass

    def redhat_compat(self): # redhat, rhel, centos, rocky, alma, amzn, ol, etc
        pass

    def redhat(self):
        pass

    def ubuntu(self):
        pass

    def suse(self):
        pass

    def macos(self):
        pass

    def windows(self):
        pass

    def msys2(self):
        pass
    
    def cygwin(self):
        pass

    def bsd_compat(self):
        pass

    def freebsd(self):
        pass

    def linuxmint(self):
        pass

    def amzn(self):
        pass

    def alpine(self):
        pass

    def raspbian(self):
        pass

    def mariner(self):
        pass

    def azurelinux(self):
        pass
