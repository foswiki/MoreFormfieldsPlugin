"use strict";jQuery((function(e){var t={minimumInputLength:0,placeholder:"None",url:null,width:"element",multiple:!1,quietMillis:500};e(".foswikiSelect2Field:not(.inited)").livequery((function(){var i=e(this),l=e.extend({},t,i.data()),n=e.extend({},l),u=i.val();delete n.minimumInputLength,delete n.url,delete n.width,delete n.quietMillis,delete n.valueText,i.addClass("inited").select2({allowClear:!0,placeholder:l.placeholder,minimumInputLength:l.minimumInputLength,width:l.width,multiple:l.multiple,ajax:{url:l.url,dataType:"json",data:function(t,i){return e.extend({},{q:t,limit:10,page:i},n)},results:function(e,t){return e.more=10*t<e.total,e}},initSelection:function(t,i){var n,d;l.multiple?(n=[],e(u.split(/\s*,\s*/)).each((function(){d=decodeURIComponent(l.valueText[this]||this),n.push({id:this,text:d})}))):(d=decodeURIComponent(l.valueText),n={id:u,text:d}),i(n)}})}))}));
