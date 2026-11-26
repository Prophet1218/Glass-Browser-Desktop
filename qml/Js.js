.pragma library

// Átlátszó weboldal háttér (mint a Zen böngészőben): a html és a body háttere áttetsző, így
// alatta az üveges ablak (és a KWin elmosás) látszik. [alpha] 0..1: maradék háttér.
function transparentCss(on, alpha, dark) {
    var bg = on ? (dark ? "rgba(8,10,18," + alpha + ")" : "rgba(250,250,252," + alpha + ")") : "";
    return "(function(){var id='__glass_bg';var st=document.getElementById(id);" +
        "if(!" + (on ? "true" : "false") + "){if(st)st.remove();return;}" +
        "if(!st){st=document.createElement('style');st.id=id;(document.head||document.documentElement).appendChild(st);}" +
        "st.textContent='html,body{background:transparent !important;background-color:transparent !important}" +
        "html{background-color:" + bg + " !important}';})();";
}

// A lebegő üvegsáv alá csúszó tartalom: a lap tetejére [h] képpont térköz kerül, a rögzített
// (fixed / sticky) fejlécek ugyanennyivel lejjebb tolódnak (mint a telefonos változatban).
function topPadJs(h) {
    return "(function(){var H=" + Math.round(h) + ";var d=document;if(!d.documentElement)return;" +
        "var st=d.getElementById('__glass_top');" +
        "if(H>0){if(!st){st=d.createElement('style');st.id='__glass_top';d.documentElement.appendChild(st);}" +
        "st.textContent='html{padding-top:'+H+'px !important;box-sizing:border-box !important}';}else if(st){st.remove();}" +
        "function chk(e){if(!e||e.nodeType!==1)return;" +
        "if(e.__gbT!==undefined){if(e.__gbH!==H){if(H>0)e.style.setProperty('top',(e.__gbT+H)+'px','important');else{e.style.removeProperty('top');delete e.__gbT;}e.__gbH=H;}return;}" +
        "if(e.__gbP!==undefined){if(e.__gbH!==H){if(H>0)e.style.setProperty('padding-top',(e.__gbP+H)+'px','important');else{e.style.removeProperty('padding-top');delete e.__gbP;}e.__gbH=H;}return;}" +
        "if(H<=0)return;var cs=getComputedStyle(e);var pos=cs.position;if(pos!=='fixed'&&pos!=='sticky')return;" +
        "var r=e.getBoundingClientRect();if(r.height<=0)return;var t=parseFloat(cs.top);" +
        "if(!isNaN(t)&&t>=0&&t<4){if(r.height<innerHeight*0.5){e.__gbT=t;e.__gbH=H;e.style.setProperty('top',(t+H)+'px','important');return;}" +
        "if(pos==='fixed'){var pt=parseFloat(cs.paddingTop)||0;e.__gbP=pt;e.__gbH=H;e.style.setProperty('padding-top',(pt+H)+'px','important');}}}" +
        "function full(){if(!d.body)return;var all=d.body.getElementsByTagName('*');for(var i=0;i<all.length;i++)chk(all[i]);}" +
        "full();var key=''+H;if(window.__gbTimer!==key){window.__gbTimer=key;setTimeout(full,600);setTimeout(full,2000);}" +
        "if(!window.__gbObs&&window.MutationObserver){var pend=[],tm=0;" +
        "function flush(){tm=0;var p=pend;pend=[];for(var i=0;i<p.length;i++){var n=p[i];n.__gbQ=0;chk(n);" +
        "if(n.__gbSub&&n.getElementsByTagName){var sub=n.getElementsByTagName('*');for(var j=0;j<sub.length&&j<400;j++)chk(sub[j]);}n.__gbSub=0;}}" +
        "window.__gbObs=new MutationObserver(function(ms){for(var i=0;i<ms.length;i++){var m=ms[i];" +
        "if(m.type==='childList'){for(var k=0;k<m.addedNodes.length;k++){var n=m.addedNodes[k];if(n.nodeType===1){n.__gbSub=1;if(!n.__gbQ){n.__gbQ=1;pend.push(n);}}}}" +
        "else if(m.target.nodeType===1&&!m.target.__gbQ&&m.target.__gbT===undefined){m.target.__gbQ=1;pend.push(m.target);}}" +
        "if(!tm&&pend.length)tm=setTimeout(flush,180);});" +
        "window.__gbObs.observe(d.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['class','style']});}" +
        "})();";
}

// Egyszerű kozmetikai reklámelrejtés (a hálózati szűrő mellé).
var adCss = "(function(){if(document.getElementById('__glass_ad'))return;var s=document.createElement('style');s.id='__glass_ad';" +
    "s.textContent='ins.adsbygoogle,[id^=\"google_ads\"],[id^=\"div-gpt-ad\"],.adsbygoogle,[data-ad-slot],[class*=\"ad-container\"],[class*=\"AdContainer\"],iframe[src*=\"doubleclick\"],.ad-banner,.adBanner,#ad_banner{display:none !important}';" +
    "(document.head||document.documentElement).appendChild(s);})();";

function formatBytes(b) {
    if (b <= 0) return "0 B";
    var u = ["B", "KB", "MB", "GB"]; var i = 0;
    while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
    return (i === 0 ? b : b.toFixed(1)) + " " + u[i];
}
