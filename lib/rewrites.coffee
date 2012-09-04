module.exports = [
	from: "/static/*"
	to: "static/*"
,
	require('spine-adapter/rewrites')
,
	from: "/"
	to: "_show/root"
,
	from: "*"
	to: "_show/not_found"
]