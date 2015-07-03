  formatter = {}

  format = (editor)  ->
    wholeFile = editor.getGrammar().name == 'Plain Text'
    if wholeFile
      text = editor.getText()
      editor.setText(formatter.pretty(text))
    else
      text = editor.replaceSelectedText({}, (text) ->
        formatter.pretty(text)
      )

  extractSipMessage = (editor)  ->
    text = editor.getText()
    atom.workspace.open().then (newEditor) ->
      newEditor.setText(formatter.extractSip(text))
      #atom.notifications.addSuccess("Extracted SIP message to the new file")

  extractScript =  (editor)  ->
    text = editor.getText()
    atom.workspace.open().then (newEditor) ->
      newEditor.setText(formatter.extractScript(text))

  formatter.extractScript = (text) ->
    scriptStart = /[^#]*#TROPO#:/g
    scriptEnd = /line\s(\d{3,4})/g
    try
      lines = text.split("\n")
      newLines = []
      for line in lines
        do (line) ->
          if line.match(scriptEnd)
            newLines.push(line.replace(scriptStart, "").replace(/\\s/g, "/"))
      newLines.sort (a, b) -> 
        array1 = new RegExp("line\\s(\\d{3,4})","g").exec(a)
        array2 = new RegExp("line\\s(\\d{3,4})","g").exec(b)
        return array1[1] - array2[1]
      return newLines.join("\n")
    catch error
      text

  formatter.pretty = (text) ->
    try
      return text.replace(/\\\\r\\\\n/g, "\r\n")
    catch error
      text

  formatter.extractSip = (text) ->
    try
      lines = text.split("\n")
      newLines = []
      for line in lines
        do (line) ->
          if line.match(/((#SIP#: \((o|i)\))|(Received (request|response)))/g)
            newLines.push(formatter.pretty(line))
      return newLines.join("\n")
    catch error
      text

  module.exports =
    activate: ->
      atom.commands.add 'atom-workspace',
        'atom-prism:format': ->
          editor = atom.workspace.getActiveTextEditor()
          format(editor)
        'atom-prism:extractSipMessage': ->
          editor = atom.workspace.getActiveTextEditor()
          extractSipMessage(editor)
        'atom-prism:extractScript': ->
          editor = atom.workspace.getActiveTextEditor()
          extractScript(editor)
