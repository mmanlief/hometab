$ = window.jQuery
Spine = require("spine/core")
utils = require("duality/utils")
{_} = require("underscore")
querystring = require("querystring")

require("spine-adapter/couch-ajax")

templates = require("duality/templates")

class Page extends Spine.Model
	@configure "Page", "page_url", "visited_count", "page_title"

	@extend Spine.Model.CouchAjax

	@visitedSort: (l, r) ->
		if(l.visited_count < r.visited_count) then 1 else -1

class Pages extends Spine.Controller
	events:
		"click .remove-container"	: "remove"
		"click .page-item-tooltip"	: "visit"
		"click .info-btn"			: "visit"

	elements:
		".page-item-tooltip"		: "titles"
		".info-btn"					: "infos"

	constructor: ->
		super
		@item.bind("update", @render)
		@item.bind("destroy", @release)
		if(!(@item.page_title?))
			@updateTitle()

	template: (item) ->
		templates.render("template_page.html", {}, item)

	render: =>
		@replace($(@template(Page.find(@item.id))))
		@titles.tooltip()
		@infos.tooltip()
		@

	remove: ->
		@item.destroy()

	visit: (e) ->
		e.preventDefault()
		if(!(@item.visited_count?))
			@item.visited_count = 0
		@item.visited_count = @item.visited_count + 1
		@item.save()
		#@item.trigger('refresh');
		@delay ->
			window.location.href = @item.page_url
		, 250

	updateTitle: ->
		$.ajax({
			url: "http://5.42.162.89:8090/magick/title?url=" + querystring.escape(@item.page_url),
			success: (data) =>
				@item.page_title = data
				@item.save()
		})


class PagesApp extends Spine.Controller
	elements:
		"#pages-grid"	: "items"

	constructor: ->
		super
		Page.bind("create", @addOne)
		Page.bind("refresh", @render)
		jQuery.event.props.push('dataTransfer')
		jQuery(window).on('drop', @dropped)
		Page.fetch()
		window.onbeforeunload = ->
			if Spine.CouchAjax.pending
				'''Data is still being sent to the server; 
				you may lose unsaved changes if you close the page.'''
		@centerModal(jQuery("#add-page-modal"))
		@handleQueryString()
		jQuery(window).resize(jQuery.throttle(100, @setGridPositioning))


	addOne: (page) =>
		view = new Pages(item: page)
		@items.append(view.render().el)

	addAll: =>
		Page.each(@addOne)

	create: (url) ->
		Page.create(page_url: url, visited_count: 0)

	render: =>
		pages = Page.all().sort(Page.visitedSort)
		@items.empty();
		pages.forEach(@addOne)
		@setGridPositioning()

	dropped: (e) =>
		e.preventDefault()
		if(e.dataTransfer)
			url = e.dataTransfer.getData("url")
			if(url != "")
				@create(url)

	centerModal: (modal) =>
		modal.css({
			'width': 'auto',
			'margin-left': ->
				-(modal.width() / 2)
			,'height': 'auto',
			'margin-top': ->
				-(modal.height() /2)
		})

	handleQueryString: ->
		url = window.location.href
		if(-1 != url.indexOf('?u='))
			qs = querystring.parse(url.split('?')[1])
			if(qs.u?)
				@create(querystring.unescape(qs.u))

	setGridPositioning: ->
		gridItems = jQuery("#pages-outer div[class*='grid-item']")
		windowWidth = jQuery(window).width() - 10
		itemWidth = gridItems.first().width() + 8
		itemsPerRow = Math.floor(windowWidth / itemWidth)
		itemCount = Math.min(itemsPerRow, gridItems.length - 2)
		itemsWidth = itemWidth * itemCount
		extraSpace = windowWidth - itemsWidth
		jQuery("#pages-outer").css('padding-left', (extraSpace / 2) - 7)

module.exports = PagesApp