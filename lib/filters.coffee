module.exports = {
	"usermodel" : (doc, req) ->
		doc.modelname == "user" && doc.user_name == req.userCtx.name
}