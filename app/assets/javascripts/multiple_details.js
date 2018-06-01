$(document).ready(function () {
    if (!window.location.pathname.match(/^\/admin\/time_entries\/?$/)) return;
    $('select').chosen();

    $('#q_details_contains_input').append($('<a class="pointer details-contains-or">OR</a>'));
    $('#q_details_contains_input').find('abbr').remove();
    $('textarea[name="q[details_contains]"]')[0].name += '[]';

    $(document).delegate('.details-contains-or', 'click', function () {
        var identifier = Date.now() % 1000;
        var $parent = $(this).parents('*[id^=q_details_contains_input]');
        var $element = $parent.clone().attr('id', 'q_details_contains_input' + identifier);
        $element.find('textarea').attr({'name': 'q[details_contains][]', 'id': 'q_details_contains' + identifier }).val('').html('');
        $parent.after($element);
        $(this).parent().append($(this).html());
        $(this).remove();

    });

    $(document).delegate("*[name='q[details_contains][]']", 'keypress', function (e) {
        if(e.which === 13 && !e.shiftKey) {
            //submit form via ajax, this is not JS but server side scripting so not showing here
            $(this).closest('form').submit();
            e.preventDefault();
            return false
        }
    });

    var params = getUrlParameters();

    if (params.has("q[details_contains][]")) {
        var detailsParams = params.get("q[details_contains][]");

        for (var i = 0; i < detailsParams.length; i++) {
            if (i > 0) $('.details-contains-or').click();
            $('textarea[name="q[details_contains][]"]').eq(i).val(detailsParams[i]).html(detailsParams[i]);
        }


    }

    function getUrlParameters() {
        var pageParamString = decodeURIComponent(window.location.search.substring(1));
        var paramsArray = pageParamString.split('&').filter(function(item) { return item !== "" });
        var paramsHash = new Map();
        for (var i = 0; i < paramsArray.length; i++) {
            var singleParam = paramsArray[i].split('=');

            if (paramsHash.has(singleParam[0])) {
                paramsHash.get(singleParam[0]).push(singleParam[1].replace(/(\w)?\+(\w)?/g, '$1 $2'));
            } else {
                paramsHash.set(singleParam[0], [singleParam[1].replace(/(\w)?\+(\w)?/g, '$1 $2')]);
            }
        }

        return paramsHash;
    }
});