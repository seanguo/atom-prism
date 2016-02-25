  formatter = {}

  format = (editor)  ->
    selection = editor.getSelectedText()
    if selection
      text = editor.replaceSelectedText({}, (text) ->
        formatter.pretty(text)
      )
    else
      text = editor.getText()
      editor.setText(formatter.pretty(text))
    editor.setGrammar(atom.grammars.grammarForScopeName("text.prism"))

  extractSipMessage = (editor)  ->
    text = editor.getText()
    atom.workspace.open().then (newEditor) ->
      newEditor.setText(formatter.extractSip(text))
      #atom.notifications.addSuccess("Extracted SIP message to the new file")

  extractScript =  (editor)  ->
    text = editor.getText()
    atom.workspace.open().then (newEditor) ->
      ret = formatter.extractScript(text);
      newEditor.setText(ret.text)
      if ret.type
        type = ret.type
        if ret.type == 'jython'
          type = 'python'
        if ret.type == 'jruby'
          type = 'ruby'
        else if ret.type == 'groovy' && !atom.grammars.grammarForScopeName("source.groovy")?
          type = 'java'
        grammar = atom.grammars.grammarForScopeName("source.#{type}")
        grammar ?= atom.grammars.grammarForScopeName("text.html.#{type}")
        newEditor.setGrammar(grammar)

  formatter.extractScript = (text) ->
    ret = {}
    scriptStart = /[^#]*#TROPO#:/g
    scriptEnd = /line\s(\d{1,4})/g
    scriptType = /of\stype\s(.+),/g
    type = null
    try
      lines = text.split("\n")
      newLines = []
      for line in lines
        do (line) ->
          if line.match(scriptType)
            if not ret.type?
              ret.type = scriptType.exec(line)[1]
          if line.match(scriptEnd)
            newLines.push(line.replace(scriptStart, "").replace(/\\s/g, "/"))
      newLines.sort (a, b) ->
        array1 = new RegExp("line\\s(\\d{1,4})","g").exec(a)
        array2 = new RegExp("line\\s(\\d{1,4})","g").exec(b)
        return array1[1] - array2[1]
      ret.text = newLines.join("\n")
    catch error
      ret.text = text
    return ret

  formatter.pretty = (text) ->
    try
      return text.replace(/\\\\r\\\\n/g, "\r\n").replace(/\\r\\n/g, "\r\n").replace(/\\s/g, "/")
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
