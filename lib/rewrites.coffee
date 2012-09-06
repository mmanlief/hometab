module.exports = [
	from: "/static/*"
	to: "static/*"
,
	require('spine-adapter/rewrites')
,
	from: "/"
	to: "_show/root"
,
	from: "/create_account"
	to: "_update/create_account"
	method: "POST"
,
	from: "/create_account"
	to: "_show/create_account"
,
	from: "*"
	to: "_show/not_found"
]