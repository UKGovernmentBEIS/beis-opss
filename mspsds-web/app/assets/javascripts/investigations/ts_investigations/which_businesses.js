$(document).ready(function () {
  var normalElements = [
    $('#businesses_retailer')[0],
    $('#businesses_distributor')[0],
    $('#businesses_importer')[0],
    $('#businesses_manufacturer')[0]
  ];
  var elementOther = $('#businesses_other')[0];
  var elementNone = $('#businesses_none')[0];

  var deselectOthers = function () {
    normalElements.forEach(function (element) {
      element.checked = false;
    });
    if (elementOther.checked) {
      // This element must be clicked because it is responsible for showing and hiding a text box, which doesn't happen
      // if the checked property is manually set to true
      elementOther.click();
      elementNone.checked = true;
    }
  };

  var deselectNone = function () {
    elementNone.checked = false;
  };

  elementNone.addEventListener('input', deselectOthers);

  normalElements.forEach(function (element) {
    element.addEventListener('input', deselectNone);
  });

  elementOther.addEventListener('input', deselectNone);
});
