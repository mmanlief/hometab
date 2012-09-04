templates = require("duality/templates")

exports.root = (doc, req) ->
	title: "HomeTab",
	content: templates.render("base.html", req, {})