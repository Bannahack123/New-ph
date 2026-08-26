function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return createJsonResponse({ status: "ERROR", message: "Empty request payload received." });
    }

    var request = JSON.parse(e.postData.contents);
    var action = request.action;
    
    var folderName = "Pharoah_ERP_Cloud";
    var folders = DriveApp.getFoldersByName(folderName);
    var folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);

    // 1. PUSH STORE DATA (Mobile App -> Cloud)
    if (action === "PUSH_STORE_DATA") {
      var storeToken = request.storeToken;
      if (!storeToken) {
        return createJsonResponse({ status: "ERROR", message: "Store Token is missing." });
      }
      
      var fileName = storeToken + ".json";
      var files = folder.getFilesByName(fileName);
      if (files.hasNext()) {
        var existingFile = files.next();
        existingFile.setContent(JSON.stringify(request));
      } else {
        folder.createFile(fileName, JSON.stringify(request), MimeType.PLAIN_TEXT);
      }
      
      return createJsonResponse({
        status: "SUCCESS",
        message: "Store data saved on cloud relay."
      });
    }

    // 2. PULL STORE DATA (Cloud -> Web Portal Browser)
    if (action === "PULL_STORE_DATA") {
      var storeToken = request.storeToken;
      var inputUser = (request.username || "").trim().toLowerCase();
      var inputPass = (request.password || "").trim();
      var fileName = storeToken + ".json";
      
      var files = folder.getFilesByName(fileName);
      if (!files.hasNext()) {
        return createJsonResponse({
          status: "ERROR",
          message: "Store Key not found. Please tap 'SYNC NOW' in mobile app first."
        });
      }

      var storeData = JSON.parse(files.next().getBlob().getDataAsString());
      var savedUser = (storeData.adminUser || "").trim().toLowerCase();
      var savedPass = (storeData.adminPassword || "").trim();
      
      if (savedUser === inputUser && savedPass === inputPass) {
        return createJsonResponse({
          status: "SUCCESS",
          companyName: storeData.companyName,
          fy: storeData.fy,
          registryProfile: storeData.registryProfile,
          files: storeData.files,
          syncedAt: storeData.syncedAt
        });
      } else {
        return createJsonResponse({
          status: "ERROR",
          message: "Invalid Username or Password for this Store Key."
        });
      }
    }

    return createJsonResponse({ status: "ERROR", message: "Unknown action: " + action });

  } catch (err) {
    return createJsonResponse({ status: "ERROR", message: err.toString() });
  }
}

function doGet(e) {
  return createJsonResponse({
    status: "ACTIVE",
    service: "Pharoah ERP Cloud Relay Engine",
    time: new Date().toISOString()
  });
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
