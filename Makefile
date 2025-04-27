AWK = awk
FIND = find
MAKEWHATIS = /usr/libexec/makewhatis
MANDOC = mandoc
MKDIR_P = mkdir -p
SED = sed

BASE_URL = https://manp.gs/mac/
# MANDIR=/usr/share/man
MANDIR = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man
MANDIRS = $(shell cat mandirs || :)

html = $(shell cd "$(MANDIR)" && $(FIND) * ! -type d \
	! -name pcap_compile.3pcap.in \
	! -name TextureProcessorMetal.metallib | \
	$(SED) -E '\
		s/^[^/]*\/|\.gz$$//g; \
		s/(\.[1n])tcl$$/\1/; \
		s/Parse::Yapp.*\.3$$/&pm/; \
		s/^index\.3$$/-&/; \
		s|(.*)\.([^.]*$$)|\2/\1.html|; \
		s/[: ]/\\&/g; \
	')

dirs = $(shell cd "$(MANDIR)" && printf "%s\n" * 1m 3G 3cc 3pcap 3pm 3tcl 3x | \
	$(SED) 's/man//g' | sort)

all: mandirs $(dirs) index.html
	set -eu; for dir in $(MANDIRS); do $(MAKE) MANDIR=$$dir html; done
	$(MAKE) sitemap.xml

mandirs:
	-$(FIND) /Applications/Xcode.app -path '*/share/man' >mandirs
	-echo /System/Cryptexes/App/usr/share/man >>mandirs

html: $(html)

whatis: mandirs
	$(MAKEWHATIS) -o "$@" $(MANDIRS)

clean:
	$(RM) -r $(dirs) index.html sitemap.xml whatis mandirs

$(dirs):
	$(MKDIR_P) "$@"

man2html = $(MANDOC) -Oman=../%S/%N,style=../style.css -Thtml "$<" | \
	$(SED) '/<pre>/,/<\/pre>/{/^<br\/>$$/d;}; \
		s/<html>/<html lang="en">/; \
		/head-vol/s|>\(.*\)<|><a href=".">\1</a><|; \
		/foot-os/s|>\(.*\)<|><a href="..">\1</a><| \
	'

convert = $(man2html) > "$@"

template = <!doctype html>\n<html lang="en">\n\
\40<head>\n\
\40\40\40<meta charset="utf-8">\n\
\40\40\40<meta name="viewport" content="width=device-width, initial-scale=1.0">\n\
\40\40\40<title>%s</title>\n\
\40\40\40<link rel="stylesheet" href="%s">\n\
\40</head>\n\
\40<body>\n\
\40\40\40<header>\n\
\40\40\40\40\40%s\n\
\40\40\40\40\40<h1>%s</h1>\n\
\40\40\40</header>\n\
\40\40\40<main>\n%s\n\
\40\40\40</main>\n\
\40</body>\n</html>\n

sitemap = <?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n%s\n</urlset>\n

desc = desc() { \
case $$1 in \
1) echo User Commands ;; \
1m) echo DTrace Commands ;; \
2) echo System Calls ;; \
3) echo C Library Functions ;; \
3G) echo OpenGL Functions ;; \
3cc) echo Common Crypto Functions ;; \
3pcap) echo Packet Capture Functions ;; \
3pm) echo Perl Modules ;; \
3tcl) echo Tcl/Tk Functions ;; \
3x) echo Curses Functions ;; \
4) echo Devices and Special Files ;; \
5) echo File Formats and Conventions ;; \
6) echo Games et. Al. ;; \
7) echo Miscellanea ;; \
8) echo System Administration Tools and Daemons ;; \
9) echo System Kernel Interfaces ;; \
n) echo Tcl/Tk Commands ;; \
esac; \
};

index.html: $(addsuffix /index.htm,$(dirs))
	$(desc) \
	printf '$(template)' "macOS man pages" "style.css" "macOS" "Manual Pages" "$$(\
		printf '      <table class="sections">\n        <thead><tr><th>Section</th><th>Title</th></tr></thead>\n        <tbody>\n'; \
		for s in $(dirs); do \
			printf '          <tr><td>%s</td><td><a href="%s">%s</a></td></tr>\n' \
				"$$s" "$$s" "$$(desc "$$s")"; \
		done; \
		printf '        </tbody>\n      </table>\n' \
	)" > "$@"

sitemap.xml:
	printf '$(sitemap)' "$$(\
		(echo && printf '%s/\n' $(dirs)) | while read dir; do \
			printf "  <url><loc>%s%s</loc></url>\n" "$(BASE_URL)" "$$dir"; \
		done; \
		$(FIND) $(dirs) -type f ! -name index.htm | sort | $(AWK) '{ \
			sub(/\.[^.]+$$/, ""); \
			gsub(/ /, "%20"); \
			gsub(/\[/, "%5B"); \
			printf "  <url><loc>%s%s</loc></url>\n", "$(BASE_URL)", $$0; \
		}'; \
	)" > "$@"

%/index.htm: whatis
	$(desc) \
	sect=$$(dirname "$@"); \
	printf '$(template)' "man$$sect &middot; macOS" "../style.css" \
		"$$(printf '<nav><a href="../" class="os">macOS</a><div class="section">man%s</div></nav>' "$$sect")" \
		"$$(desc "$$sect")" "$$(\
		printf '      <table class="whatis">\n        <thead><tr><th>Name</th><th>Summary</th></tr></thead>\n        <tbody>\n'; \
		if [ "$$sect" = 1 ] || [ "$$sect" = n ]; then \
			sect="$$sect\(tcl\)\{0,1\}"; \
		fi; \
		$(SED) -n -e ' \
			s/</\&lt;/g; \
			s/>/\&gt;/g; \
			h; \
			s/ - /\n/; \
			s/.*\n//; \
			x; \
			s/ - .*//; \
		' -e "/($$sect)/!b" -e ' \
			s/"/\&quot;/g; \
			s|\([^, ][^,]*\)([0-9n][^)]*)|<a href="./\1">&</a>|g; \
		' -e ':percent' -e ' \
			s|\(href="[^"]*\)%\([^2]\)|\1%25\2|g; \
		' -e 't percent' -e ' \
		' -e ':escape' -e ' \
			s|\(href="[^"]*\) |\1%20|g; \
			s|\(href="[^"]*\)&quot;|\1%22|g; \
			s|\(href="[^"]*\)&lt;|\1%3C|g; \
			s|\(href="[^"]*\)&gt;|\1%3E|g; \
			s|\(href="[^"]*\)\[|\1%5B|g; \
			s|\(href="[^"]*\){|\1%7B|g; \
			s|\(href="[^"]*\)}|\1%7D|g; \
		' -e 't escape' -e ' \
			s|href="\./index"|href="./-index"|; \
			s|^|          <tr><td class="names">|; \
			G; \
			s|\n|</td><td class="summary">|; \
			s|$$|</td></tr>|p; \
		' whatis; \
		printf '        </tbody>\n      </table>\n' \
	)" > "$@"

# Special cases

1/[.html: $(MANDIR)/man1/[.1
	$(convert)

3/-index.html: $(MANDIR)/man3/index.3
	$(convert)

3/MPSCNNBatchNormalizationDataSource\ -p.html: $(MANDIR)/man3/MPSCNNBatchNormalizationDataSource\ -p.3
	$(convert)

3/MPSCNNConvolutionDataSource\ -p.html: $(MANDIR)/man3/MPSCNNConvolutionDataSource\ -p.3
	$(convert)

3/MPSCNNInstanceNormalizationDataSource\ -p.html: $(MANDIR)/man3/MPSCNNInstanceNormalizationDataSource\ -p.3
	$(convert)

3/MPSHandle\ -p.html: $(MANDIR)/man3/MPSHandle\ -p.3
	$(convert)

3/MPSImageAllocator\ -p.html: $(MANDIR)/man3/MPSImageAllocator\ -p.3
	$(convert)

3/MPSImageSizeEncodingState\ -p.html: $(MANDIR)/man3/MPSImageSizeEncodingState\ -p.3
	$(convert)

3/MPSImageTransformProvider\ -p.html: $(MANDIR)/man3/MPSImageTransformProvider\ -p.3
	$(convert)

3/MPSNNPadding\ -p.html: $(MANDIR)/man3/MPSNNPadding\ -p.3
	$(convert)

3/MPSNNTrainableNode\ -p.html: $(MANDIR)/man3/MPSNNTrainableNode\ -p.3
	$(convert)

3cc/Common\ Crypto.html: $(MANDIR)/man3/Common\ Crypto.3cc
	$(convert)

8/Keychain\ Circle\ Notification.html: $(MANDIR)/man8/Keychain\ Circle\ Notification.8
	$(convert)

8/Photo\ Library\ Migration\ Utility.html: $(MANDIR)/man8/Photo\ Library\ Migration\ Utility.8
	$(convert)

8/Script\ Menu.html: $(MANDIR)/man8/Script\ Menu.8
	$(convert)

8/bluetoothuserd.html: $(MANDIR)/man1/bluetoothuserd.8
	$(convert)

8/deleted_helper.html: $(MANDIR)/man1/deleted_helper.8
	$(convert)

8/securityuploadd.html: $(MANDIR)/man1/securityuploadd.8
	$(convert)

8/silhouette.html: $(MANDIR)/man1/silhouette.8
	$(convert)

8/usbctelemetryd.html: $(MANDIR)/man1/usbctelemetryd.8
	$(convert)

# Sections

1m/%.html: $(MANDIR)/man1/%.1m
	$(convert)

1/%.html: $(MANDIR)/man1/%.1*
	$(convert)

2/%.html: $(MANDIR)/man2/%.2
	$(convert)

3/%.html: $(MANDIR)/man3/%.3
	$(convert)

3G/%.html: $(MANDIR)/man3/%.3G
	$(convert)

3cc/%.html: $(MANDIR)/man3/%.3cc
	$(convert)

3pcap/%.html: $(MANDIR)/man3/%.3pcap
	$(convert)

# files have colons in them
3pm/%.html: $(MANDIR)/man3/%.3*
	$(man2html) >$@

3tcl/%.html: $(MANDIR)/man3/%.3tcl
	$(convert)

3x/%.html: $(MANDIR)/man3/%.3x
	$(convert)

4/%.html: $(MANDIR)/man4/%.4
	$(convert)

5/%.html: $(MANDIR)/man5/%.5*
	$(convert)

6/%.html: $(MANDIR)/man6/%.6
	$(convert)

7/%.html: $(MANDIR)/man7/%.7
	$(convert)

8/%.html: $(MANDIR)/man8/%.8
	$(convert)

9/%.html: $(MANDIR)/man9/%.9
	$(convert)

# some files have colons in them
n/%.html: $(MANDIR)/mann/%.n*
	$(man2html) >$@
