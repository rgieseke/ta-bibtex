-- The bibtex module for the
-- [Textadept](http://foicica.com/textadept/) editor.
-- It provides helpers for editing BibTeX files
-- and inserting items in LaTeX or ConTeXt files.
--
-- The [source](https://github.com/rgieseke/ta-bibtex) is on
-- GitHub,
-- released under the
-- [MIT license](http://www.opensource.org/licenses/mit-license.php).
--
-- ## Installation
-- Clone the git repository to your `.textadept` directory:
--     cd ~/.textadept/modules
--     git clone https://github.com/rgieseke/ta-bibtex.git bibtex
--
-- ## Usage
-- You can load this module in your LaTeX or ConTeXt module, define the
-- locations of your BibTeX files and include it in snippets.
-- To only add a key you could assign `select_reference` to a shortcut key.<br>
-- Be aware however that the parsing code might not work for all possible ways
-- of writing BibTeX files. For me it worked well with the output from
-- [Google Scholar](http://scholar.google.com/intl/en/scholar/help.html#export)
-- and other sources.<br>
-- Example code in your `tex` or `latex` module:
--     _M.bibtex = require('bibtex')
--     _M.bibtex.files = {'/home/robert/documents/bibligraphy.bib'}
--
--     -- ConTeXt snippet example
--     snippets.tex = {
--         -- …
--         c = "\\cite[%%<_M.bibtex.select_reference()>]%%0",
--     }
--
--     -- LaTeX snippet example
--     snippets.latex = {
--         -- …
--         c = "\\cite{%%<_M.bibtex.select_reference()>}%%0",
--     }

local M = {}

-- ## Fields

-- ___M.bibtex.files__: A table with BibTeX files.
M.files = {}

-- ___M.bibtex.references__: A table with references and their BibTeX key.
M.references = {}

-- ## Commands

-- Try to read entries from a BibTeX file. Author, year and title are
-- joined for an entry in the `references` table, followed by its BibTeX key.
local function parse_entries(filename)
  file = io.open(filename, 'rb')
  bibentries = file:read('*all')
  file:close()
  for bibentry in bibentries:gmatch('@.-\n}\n') do
    key = bibentry:match('@%w+{(.-),') or ''
    author = bibentry:match('author%s*=%s*["{]*(.-)["}],?')..', ' or ''
    year = bibentry:match('year%s*=%s*["{]?(%d+)["}]?,?')..', ' or ''
    title = bibentry:match('title%s*=%s*["{]*(.-)["}],?') or ''
    M.references[#M.references + 1] = author..year..title
    M.references[#M.references + 1] = key
  end
end

-- Read BibTeX entries from the files listed in the `files` table.
local function read_bibfiles()
  references = {}
  for _, bibfile in ipairs(M.files) do
    parse_entries(bibfile)
  end
end

-- Present a filtered list dialog and return the BibTeX key of the selected
-- entry.
function M.select_reference()
  if #M.files > 0 and #M.references == 0 then
    read_bibfiles()
  end
  if #M.references > 0 then
    local status, item = ui.dialogs.filteredlist{
      title='References',
      columns={'Reference', 'Key'},
      items=M.references,
      string_output=true,
      ['output-column']=2,
      width=900
    }
    if item then
      return item -- the BibTeX key
    end
  end
end


-- ## Snippets

-- Container for BibTeX-specific snippets.
snippets.bibtex = {
    ['@'] = [[
@%1(article){%2(key),
 author = {%3},
 title = {%4},
 publisher = {%5},
 year = {%6},
}
]]
  }

return M
