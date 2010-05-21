class Source.rb

  def cmd_source(message)
    reply(message, "This software is licensed under the GNU Affero General Public License. You may acquire the source code at http://github.com/kabaka/Terminus-Bot or view the full license at http://www.gnu.org/licenses/agpl-3.0.html")
  end

end

$modules.push(Source.new)
