require 'formula'

class GrOsmosdr < Formula
    homepage 'http://sdr.osmocom.org/trac/wiki/GrOsmoSDR'
    head 'git://git.osmocom.org/gr-osmosdr', :branch => 'master'

    depends_on 'cmake' => :build
    depends_on 'gnuradio'

    def install
        mkdir 'build' do
            system 'cmake', '..', '-DENABLE_REDPITAYA=OFF'
            system 'make'
            system 'make install'
        end
    end

    def python_path
        python = Formula.factory('python')
        kegs = python.rack.children.reject { |p| p.basename.to_s == '.DS_Store' }
        kegs.find { |p| Keg.new(p).linked? } || kegs.last
    end
end
