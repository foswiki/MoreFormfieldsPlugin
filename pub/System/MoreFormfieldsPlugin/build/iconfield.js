"use strict";jQuery((function(e){var t={minimumInputLength:0,url:foswiki.getPreference("SCRIPTURL")+"/rest/MoreFormfieldsPlugin/icon",width:"element",multiple:!1,quietMillis:500,placeholder:"None",pageSize:20};function i(e,t){return void 0===e.id?e.text:e.url?'<img src="'+e.url+'" class="foswikiIcon" /> '+e.text:/^(\w+)\-/.exec(e.id)?'<i class="'+RegExp.$1+" fa-fw "+e.id+'"></i> '+e.text:e.text}e(".foswikiIconField:not(.inited)").livequery((function(){var n=e(this),l=e.extend({},t,n.data()),a=n.val();n.addClass("inited").select2({allowClear:!0,placeholder:l.placeholder,minimumInputLength:l.minimumInputLength,width:l.width,multiple:l.multiple,formatSelection:i,formatResult:i,_escapeMarkup:function(e){return e},ajax:{url:l.url,dataType:"json",data:function(e,t){return{q:e,limit:l.pageSize,page:t,cat:l.cat,include:l.include,exclude:l.exclude}},results:function(e,t){return e.more=t*l.pageSize<e.total,e}},initSelection:function(t,i){var n;""!==a&&(n={q:a,limit:1,cat:l.cat,exact:1},e.ajax(l.url,{data:n,dataType:"json"}).done((function(e){void 0!==e.results&&i(e.results[0])})))}})}))}));
