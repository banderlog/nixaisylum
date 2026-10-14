## maximum amount of system tools for local AI agent
# better use with python
{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Core Shell & Process utilities
    coreutils
    findutils
    bash
    gnused
    gawk
    miller
    diffutils
    patch
    procps        # ps, pkill, free, top
    moreutils
    lsof
    strace
    socat
    dnsutils
    wget

    # Search, Inspection & CLI tools (vital for agent reasoning/navigation)
    ripgrep       # Fast code/text search
    fd            # Fast file search
    tree
    file
    bc
    less
    curl
    git
    lynx          # CLI web-browser (great for text-only webpage scraping)
    jq            # JSON processing
    yq-go         # YAML
    xmlstarlet    # XML parsing
    sqlite        # SQLite CLI

    # Document, Font & Media processing
    ffmpeg
    pandoc        # Document conversion (Markdown, PDF, DOCX, HTML)
    graphicsmagick
    fontconfig
    poppler-utils

    # Archive extraction & Compression
    gnutar
    gzip
    bzip2
    xz
    zstd
    zip
    unzip
    p7zip
  ];

  # Fonts accessible to document processors (pandoc, imagemagick, etc.)
  fonts.packages = with pkgs; [
    dejavu_fonts
    corefonts     # Includes Times New Roman
  ];
}
