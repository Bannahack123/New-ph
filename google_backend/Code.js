// ===========================================================================
// 👑 PHAROAH ERP - TERMINAL CLOUD BRIDGE (AUTO-SYNC ENGINE)
// ===========================================================================

function doGet(e) {
  try {
    var action = (e && e.parameter && e.parameter.action) ? e.parameter.action : "PULL_DATA";
    var rootFolder = getOrCreateFolder(DriveApp.getRootFolder(), "Pharoah_ERP_Cloud");

    if (action === "PULL_DATA" || action === "CHECK_STATUS") {
      var result = {};
      var compFolders = rootFolder.getFolders();
      
      if (compFolders.hasNext()) {
        var compFolder = compFolders.next();
        var profileIter = compFolder.getFilesByName("profile.json");
        if (profileIter.hasNext()) {
          result["profile.json"] = profileIter.next().getBlob().getDataAsString();
        }

        var fyFolders = compFolder.getFolders();
        var targetFolder = fyFolders.hasNext() ? fyFolders.next() : compFolder;
        
        var filesIter = targetFolder.getFiles();
        while (filesIter.hasNext()) {
          var file = filesIter.next();
          result[file.getName()] = file.getBlob().getDataAsString();
        }
      }

      return ContentService.createTextOutput(JSON.stringify({
        status: "SUCCESS",
        data: result,
        hasData: Object.keys(result).length > 0,
        companyName: result["profile.json"] ? JSON.parse(result["profile.json"]).name : "PHAROAH STORE",
        timestamp: new Date().toISOString()
      })).setMimeType(ContentService.MimeType.JSON);
    }

    return ContentService.createTextOutput(JSON.stringify({ status: "ONLINE" })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ status: "ERROR", message: err.toString() })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var rootFolder = getOrCreateFolder(DriveApp.getRootFolder(), "Pharoah_ERP_Cloud");
    var companyId = data.companyId || "DEFAULT_COMPANY";
    var fy = data.fy || "2026-27";
    
    var compFolder = getOrCreateFolder(rootFolder, companyId);
    var fyFolder = getOrCreateFolder(compFolder, fy);

    if (data.action === "PUSH_DATA") {
      var files = data.files || {};
      for (var fileName in files) {
        saveOrUpdateFile(fyFolder, fileName, files[fileName]);
      }
      if (data.registryProfile) {
        saveOrUpdateFile(compFolder, "profile.json", JSON.stringify(data.registryProfile));
      }

      return ContentService.createTextOutput(JSON.stringify({
        status: "SUCCESS",
        message: "Synced to Google Drive"
      })).setMimeType(ContentService.MimeType.JSON);
    }

    return ContentService.createTextOutput(JSON.stringify({ status: "ERROR" })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ status: "ERROR", message: err.toString() })).setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateFolder(parent, name) {
  var it = parent.getFoldersByName(name);
  return it.hasNext() ? it.next() : parent.createFolder(name);
}

function saveOrUpdateFile(folder, name, content) {
  var it = folder.getFilesByName(name);
  if (it.hasNext()) {
    it.next().setContent(typeof content === 'string' ? content : JSON.stringify(content));
  } else {
    folder.createFile(name, typeof content === 'string' ? content : JSON.stringify(content));
  }
}
