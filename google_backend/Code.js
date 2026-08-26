function doPost(e) {
  try {
    var request = JSON.parse(e.postData.contents);
    var action = request.action;
    
    // Dedicated Google Drive Folder
    var folderName = "Pharoah_ERP_Cloud";
    var folders = DriveApp.getFoldersByName(folderName);
    var folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);

    // =========================================================================
    // 1. PUSH STORE DATA (Mobile App -> Cloud)
    // =========================================================================
    if (action === "PUSH_STORE_DATA") {
      var storeToken = request.storeToken;
      var fileName = storeToken + ".json";
      
      var files = folder.getFilesByName(fileName);
      if (files.hasNext()) {
        var existingFile = files.next();
        existingFile.setContent(JSON.stringify(request));
      } else {
        folder.createFile(fileName, JSON.stringify(request), MimeType.PLAIN_TEXT);
      }
      
      return ContentService.createTextOutput(JSON.stringify({
        status: "SUCCESS",
        message: "Store data saved on cloud relay."
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // =========================================================================
    // 2. PULL STORE DATA (Cloud -> Web Portal Browser)
    // =========================================================================
    if (action === "PULL_STORE_DATA") {
      var storeToken = request.storeToken;
      var inputUser = request.username;
      var inputPass = request.password;
      var fileName = storeToken + ".json";
      
      var files = folder.getFilesByName(fileName);
      if (!files.hasNext()) {
        return ContentService.createTextOutput(JSON.stringify({
          status: "ERROR",
          message: "Store Access Key not found. Please sync from mobile app first."
        })).setMimeType(ContentService.MimeType.JSON);
      }

      var storeData = JSON.parse(files.next().getBlob().getDataAsString());
      
      // Credential verification
      if (storeData.adminUser.toLowerCase() === inputUser.toLowerCase() && storeData.adminPassword === inputPass) {
        return ContentService.createTextOutput(JSON.stringify({
          status: "SUCCESS",
          companyName: storeData.companyName,
          fy: storeData.fy,
          registryProfile: storeData.registryProfile,
          files: storeData.files
        })).setMimeType(ContentService.MimeType.JSON);
      } else {
        return ContentService.createTextOutput(JSON.stringify({
          status: "ERROR",
          message: "Invalid Username or Password for this Store Key."
        })).setMimeType(ContentService.MimeType.JSON);
      }
    }

    return ContentService.createTextOutput(JSON.stringify({
      status: "ERROR",
      message: "Unknown Action."
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "ERROR",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    status: "ACTIVE",
    service: "Pharoah ERP Cloud Relay Engine"
  })).setMimeType(ContentService.MimeType.JSON);
}
