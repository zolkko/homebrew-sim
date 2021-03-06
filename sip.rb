class Sip < Formula
  desc "Tool to create Python bindings for C and C++ libraries"
  homepage "http://www.riverbankcomputing.co.uk/software/sip"
  url "https://downloads.sf.net/project/pyqt/sip/sip-4.16.8/sip-4.16.8.tar.gz"
  sha256 "d3141b65e48a30c9ce36612f8bcd1730ebf02d044757e4d6c5234927e2063e18"

  bottle do
    sha256 "d21f39098b5f241d1ea61c414961664941793e3ff5fea56b478c2ad092b7c166" => :yosemite
    sha256 "7d25d976f4bbcec265c0f144ef839b197f1593ebbf5c6740963d0ac4fc5734ea" => :mavericks
    sha256 "72383920ab69c92737f791d5e1fb06e45b8babb1d71b3e683489ca3dee8baee1" => :mountain_lion
  end

  head "http://www.riverbankcomputing.co.uk/hg/sip", :using => :hg

  # depends_on :python => :recommended
  depends_on :python3 => :optional

  #if build.without?("python3") && build.without?("python")
  #  odie "sip: --with-python3 must be specified when using --without-python"
  #end

  def install
    if build.head?
      # Link the Mercurial repository into the download directory so
      # build.py can use it to figure out a version number.
      ln_s cached_download + ".hg", ".hg"
      # build.py doesn't run with python3
      system "python", "build.py", "prepare"
    end

    Language::Python.each_python(build) do |python, version|
      # Note the binary `sip` is the same for python 2.x and 3.x
      system python, "configure.py",
                     "--deployment-target=#{MacOS.version}",
                     "--destdir=#{lib}/python#{version}/site-packages",
                     "--bindir=#{bin}",
                     "--incdir=#{include}",
                     "--sipdir=#{HOMEBREW_PREFIX}/share/sip"
      system "make"
      system "make", "install"
      system "make", "clean"

      if Formula[python].installed? && which(python).realpath == (Formula[python].bin/python).realpath
        inreplace lib/"python#{version}/site-packages/sipconfig.py", Formula[python].prefix, Formula[python].opt_prefix
      end
    end
  end

  def post_install
    mkdir_p "#{HOMEBREW_PREFIX}/share/sip"
  end

  def caveats
    "The sip-dir for Python is #{HOMEBREW_PREFIX}/share/sip."
  end

  test do
    (testpath/"test.h").write <<-EOS.undent
      #pragma once
      class Test {
      public:
        Test();
        void test();
      };
    EOS
    (testpath/"test.cpp").write <<-EOS.undent
      #include "test.h"
      #include <iostream>
      Test::Test() {}
      void Test::test()
      {
        std::cout << "Hello World!" << std::endl;
      }
    EOS
    (testpath/"test.sip").write <<-EOS.undent
      %Module test
      class Test {
      %TypeHeaderCode
      #include "test.h"
      %End
      public:
        Test();
        void test();
      };
    EOS
    (testpath/"generate.py").write <<-EOS.undent
      from sipconfig import SIPModuleMakefile, Configuration
      m = SIPModuleMakefile(Configuration(), "test.build")
      m.extra_libs = ["test"]
      m.extra_lib_dirs = ["."]
      m.generate()
    EOS
    (testpath/"run.py").write <<-EOS.undent
      from test import Test
      t = Test()
      t.test()
    EOS
    system ENV.cxx, "-shared", "-o", "libtest.dylib", "test.cpp"
    system "#{bin}/sip", "-b", "test.build", "-c", ".", "test.sip"
    Language::Python.each_python(build) do |python, version|
      ENV["PYTHONPATH"] = lib/"python#{version}/site-packages"
      system python, "generate.py"
      system "make", "-j1", "clean", "all"
      system python, "run.py"
    end
  end
end
