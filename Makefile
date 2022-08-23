# MANDIR=/usr/share/man
MANDIR = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man
BASE_URL = https://manp.gs/mac/

html = $(shell cd "$(MANDIR)" && find * ! -type d ! -name pcap_compile.3pcap.in | \
	sed -E '\
		s/^[^/]*\/|\.gz$$//g; \
		s/(\.[1n])tcl$$/\1/; \
		s|Parse::Yapp.*\.3$$|&pm|; \
		s|^index\.3$$|-&|; \
		s|(.*)\.([^.]*$$)|\2/\1.html|; \
		s|[: ]|\\&|g; \
	')

dirs = $(shell cd "$(MANDIR)" && printf "%s\n" * 1m 3G 3cc 3pcap 3pm 3tcl 3x | \
	sed 's/man//g' | sort)

MANDIRS=$(shell cat mandirs || :)

all: mandirs $(dirs) index.html
	for dir in $(MANDIRS); do $(MAKE) MANDIR=$$dir html; done
	$(MAKE) sitemap.xml

mandirs:
	-find /Applications/Xcode.app -path '*/share/man' >mandirs

html: $(html)

whatis: mandirs
	/usr/libexec/makewhatis -o "$@" $(MANDIRS)

clean:
	$(RM) -r $(dirs) index.html sitemap.xml whatis mandirs

$(dirs):
	mkdir -p "$@"

MANDOC=mandoc
FLAGS=-Oman=../%S/%N,style=../style.css
CMD=$(MANDOC) $(FLAGS) -Thtml "$<" | sed '/<pre>/,/<\/pre>/{/^<br\/>$$/d;}'
BUILD=$(CMD) > "$@"

template = <!doctype html>\n<html lang="en">\n\
\40<head>\n\
\40\40\40<meta charset="utf-8">\n\
\40\40\40<title>%s</title>\n\
\40\40\40<link rel="stylesheet" href="%s">\n\
\40</head>\n\
\40<body>\n\
\40\40\40<main>\n\
\40\40\40\40\40<h1>%s</h1>\n%s\n\
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
	printf '$(template)' "macOS Manpages" "style.css" "macOS Manpages" "$$(\
		for s in $(dirs); do \
			printf '      <h2><a href="%s">%s &mdash; %s</a></h2>\n' \
				"$$s" "$$s" "$$(desc "$$s")"; \
		done; \
	)" > "$@"

sitemap.xml:
	printf '$(sitemap)' "$$(\
		(echo "" && printf '%s/\n' $(dirs)) | while read dir; do \
			printf "  <url><loc>%s%s</loc></url>\n" "$(BASE_URL)" "$$dir"; \
		done; \
		find $(dirs) -type f ! -name index.htm | sort | awk '{ \
			sub(/\.[^.]+$$/, ""); \
			gsub(/ /, "%20"); \
			gsub(/\[/, "%5B"); \
			printf "  <url><loc>%s%s</loc></url>\n", "$(BASE_URL)", $$0; \
		}'; \
	)" > "$@"

%/index.htm: whatis
	$(desc) \
	sect=$$(dirname "$@"); \
	printf '$(template)' "man$$sect &mdash; macOS Manpages" "../style.css" \
		"<a href=\"../\">macOS</a> &mdash; $$(desc "$$sect")" "$$(\
		printf '      <ul class="whatis">\n'; \
		if [ "$$sect" = 1 ] || [ "$$sect" = n ]; then \
			sect="$$sect\(tcl\)\{0,1\}"; \
		fi; \
		sed -n -e ' \
			h; \
			s/ - /\n/; \
			s|.*\n||; \
			x; \
			s| - .*||; \
		' -e 't clear' -e :clear -e ' \
			s|('"$$sect"')|&|; \
		' -e 't link' -e b -e :link -e '\
			s|\([^, ][^(]*\)([0-9n][^)]*)|<a href="./\1">&</a>|g; \
			s|href="\./index"|href="./-index"| ; \
			s|^|        <li>|; \
			G; \
			s|\n| \&mdash; |; \
			s|$$|</li>|p; \
		' whatis; \
		printf '      </ul>\n' \
	)" > "$@"

# Special cases

1/[.html: $(MANDIR)/man1/[.1
	$(BUILD)

3/-index.html: $(MANDIR)/man3/index.3
	$(BUILD)

3/MPSCNNBatchNormalizationDataSource\ -p.html: $(MANDIR)/man3/MPSCNNBatchNormalizationDataSource\ -p.3
	$(BUILD)

3/MPSCNNConvolutionDataSource\ -p.html: $(MANDIR)/man3/MPSCNNConvolutionDataSource\ -p.3
	$(BUILD)

3/MPSCNNInstanceNormalizationDataSource\ -p.html: $(MANDIR)/man3/MPSCNNInstanceNormalizationDataSource\ -p.3
	$(BUILD)

3/MPSHandle\ -p.html: $(MANDIR)/man3/MPSHandle\ -p.3
	$(BUILD)

3/MPSImageAllocator\ -p.html: $(MANDIR)/man3/MPSImageAllocator\ -p.3
	$(BUILD)

3/MPSImageSizeEncodingState\ -p.html: $(MANDIR)/man3/MPSImageSizeEncodingState\ -p.3
	$(BUILD)

3/MPSImageTransformProvider\ -p.html: $(MANDIR)/man3/MPSImageTransformProvider\ -p.3
	$(BUILD)

3/MPSNNPadding\ -p.html: $(MANDIR)/man3/MPSNNPadding\ -p.3
	$(BUILD)

3/MPSNNTrainableNode\ -p.html: $(MANDIR)/man3/MPSNNTrainableNode\ -p.3
	$(BUILD)

3cc/Common\ Crypto.html: $(MANDIR)/man3/Common\ Crypto.3cc
	$(BUILD)

8/Keychain\ Circle\ Notification.html: $(MANDIR)/man8/Keychain\ Circle\ Notification.8
	$(BUILD)

8/Photo\ Library\ Migration\ Utility.html: $(MANDIR)/man8/Photo\ Library\ Migration\ Utility.8
	$(BUILD)

8/Script\ Menu.html: $(MANDIR)/man8/Script\ Menu.8
	$(BUILD)

8/deleted_helper.html: $(MANDIR)/man1/deleted_helper.8
	$(BUILD)

8/securityuploadd.html: $(MANDIR)/man1/securityuploadd.8
	$(BUILD)

8/silhouette.html: $(MANDIR)/man1/silhouette.8
	$(BUILD)

# Sections

1m/%.html: $(MANDIR)/man1/%.1m
	$(BUILD)

1/%.html: $(MANDIR)/man1/%.1*
	$(BUILD)

2/%.html: $(MANDIR)/man2/%.2
	$(BUILD)

3/%.html: $(MANDIR)/man3/%.3
	$(BUILD)

3G/%.html: $(MANDIR)/man3/%.3G
	$(BUILD)

3cc/%.html: $(MANDIR)/man3/%.3cc
	$(BUILD)

3pcap/%.html: $(MANDIR)/man3/%.3pcap
	$(BUILD)

# files have colons in them
3pm/%.html: $(MANDIR)/man3/%.3*
	$(CMD) > $@

3tcl/%.html: $(MANDIR)/man3/%.3tcl
	$(BUILD)

3x/%.html: $(MANDIR)/man3/%.3x
	$(BUILD)

4/%.html: $(MANDIR)/man4/%.4
	$(BUILD)

5/%.html: $(MANDIR)/man5/%.5*
	$(BUILD)

6/%.html: $(MANDIR)/man6/%.6
	$(BUILD)

7/%.html: $(MANDIR)/man7/%.7
	$(BUILD)

8/%.html: $(MANDIR)/man8/%.8
	$(BUILD)

9/%.html: $(MANDIR)/man9/%.9
	$(BUILD)

# some files have colons in them
n/%.html: $(MANDIR)/mann/%.n*
	$(CMD) > $@
