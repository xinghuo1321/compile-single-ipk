#!/bin/sh
echo SOURCECODEURL: "$SOURCECODEURL"
echo PKGNAME: "$PKGNAME"
echo BOARD: "$BOARD"
EMAIL=${EMAIL:-"aa@163.com"}
echo EMAIL: "$EMAIL"
echo PASSWORD: "$PASSWORD"

WORKDIR="$(pwd)"

sudo -E apt-get update
sudo -E apt-get install git  asciidoc bash bc binutils bzip2 fastjar flex gawk gcc genisoimage gettext git intltool jikespg libgtk2.0-dev libncurses5-dev libssl1.0-dev make mercurial patch perl-modules python2.7-dev rsync ruby sdcc subversion unzip util-linux wget xsltproc zlib1g-dev zlib1g-dev -y

git config --global user.email "${EMAIL}"
git config --global user.name "aa"
[ -n "${PASSWORD}" ] && git config --global user.password "${PASSWORD}"

# 下载需要编译插件的源代码
mkdir -p  ${WORKDIR}/buildsource
cd  ${WORKDIR}/buildsource
git clone "$SOURCECODEURL"
cd  ${WORKDIR}

x86_sdk_get()
{
	wget -q -O openwrt-sdk.tar.xz https://downloads.openwrt.org/releases/21.02.3/targets/x86/64/openwrt-sdk-21.02.3-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
	mkdir -p ${WORKDIR}/openwrt-sdk
	tar -Jxf openwrt-sdk.tar.xz -C ${WORKDIR}/openwrt-sdk --strip=1
}

case "$BOARD" in
	"SF1200" |\
	"SFT1200" )
		mips_siflower_sdk_get
	;;
	"AXT1800" )
		axt1800_sdk_get
	;;
	"X86" )
		x86_sdk_get
	;;
	*)
esac

cd openwrt-sdk
# 加入要编译插件的代码
sed -i "1i\src-link githubaction ${WORKDIR}/buildsource" feeds.conf.default

ls -l
cat feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

if ()

# 编译x64固件:
cat >> .config <<EOF
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_Generic=y
EOF

# 生成一个通用的编译系统配置
make defconfig

# 输出配置信息
cat .config

# 编译插件
make V=s ./package/feeds/githubaction/${PKGNAME}/compile

find bin -type f -exec ls -lh {} \;
find bin -type f -name "*.ipk" -exec cp -f {} "${WORKDIR}" \; 
