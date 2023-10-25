# FigmaPull

Use XPath-like selectors to export figma images

Visit https://www.figma.com/developers/api for a token

Example usage:

`swift run FigmaPull images --token <token> --format svg "Document['<key>']/*[@name='Icons page']/*[@name='Icons']/componentSet/component"`
