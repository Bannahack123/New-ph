// FILE: google_backend/Code.js
// PHAROAH ERP 2-WAY CLOUD RELAY & STORE SYNC ENGINE

function testSetup() {
  var folderName = "Pharoah_ERP_Cloud";
  var folders = DriveApp.getFoldersByName(folderName);
  var folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);
  Logger.log("✅ Google Drive Pharoah Cloud Folder Ready: " + folder.getId());
}

function getCloudFolder() {
  var folderName = "Pharoah_ERP_Cloud";
  var folders = DriveApp.getFoldersByName(folderName);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);
}

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return createJsonResponse({ status: "ERROR", message: "Empty request payload." });
    }

    var request = JSON.parse(e.postData.contents);
    var action = request.action;
    var folder = getCloudFolder();

    // 1. PUSH STORE DATA (Mobile App or Web -> Cloud Drive)
    if (action === "PUSH_STORE_DATA") {
      var storeToken = (request.storeToken || "").trim().toUpperCase();
      if (!storeToken) {
        return createJsonResponse({ status: "ERROR", message: "Store Token is missing." });
      }

      var fileName = storeToken + ".json";
      var files = folder.getFilesByName(fileName);
      
      request.syncedAt = new Date().toISOString();
      var jsonPayload = JSON.stringify(request);

      if (files.hasNext()) {
        var existingFile = files.next();
        existingFile.setContent(jsonPayload);
      } else {
        folder.createFile(fileName, jsonPayload, MimeType.PLAIN_TEXT);
      }

      return createJsonResponse({
        status: "SUCCESS",
        message: "Store snapshot synced atomically to cloud.",
        syncedAt: request.syncedAt
      });
    }

    // 2. PULL STORE DATA (Cloud Drive -> Client)
    if (action === "PULL_STORE_DATA") {
      return handlePullRequest(request.storeToken, request.username, request.password, folder);
    }

    return createJsonResponse({ status: "ERROR", message: "Unknown action: " + action });

  } catch (err) {
    return createJsonResponse({ status: "ERROR", message: err.toString() });
  }
}

function doGet(e) {
  if (e && e.parameter) {
    var action = e.parameter.action;

    // 🔍 3. LIST ALL STORES SAVED ON GOOGLE DRIVE
    if (action === "LIST_ALL_STORES") {
      try {
        var folder = getCloudFolder();
        var files = folder.getFiles();
        var storeList = [];

        while (files.hasNext()) {
          var file = files.next();
          var name = file.getName();
          if (name.endsWith(".json")) {
            try {
              var data = JSON.parse(file.getBlob().getDataAsString());
              var salesCount = 0;
              var medsCount = 0;
              if (data.files) {
                if (data.files["sales.json"]) salesCount = JSON.parse(data.files["sales.json"]).length;
                if (data.files["meds.json"]) medsCount = JSON.parse(data.files["meds.json"]).length;
              }

              storeList.push({
                storeToken: data.storeToken || name.replace(".json", ""),
                companyName: data.companyName || "Unknown",
                adminUser: data.adminUser || "admin",
                fy: data.fy || "N/A",
                totalSales: salesCount,
                totalMeds: medsCount,
                syncedAt: data.syncedAt || file.getLastUpdated().toISOString(),
                fileSizeKb: (file.getSize() / 1024).toFixed(2)
              });
            } catch(err) {
              storeList.push({ storeToken: name, error: "Parse Error" });
            }
          }
        }

        return createJsonResponse({
          status: "SUCCESS",
          totalStores: storeList.length,
          stores: storeList
        });
      } catch(err) {
        return createJsonResponse({ status: "ERROR", message: err.toString() });
      }
    }

    // PULL STORE DATA VIA GET (CORS-Safe)
    if (action === "PULL_STORE_DATA") {
      var storeToken = e.parameter.storeToken;
      var username = e.parameter.username;
      var password = e.parameter.password;
      var folder = getCloudFolder();

      return handlePullRequest(storeToken, username, password, folder);
    }
  }

  // Health Check / Ping
  return createJsonResponse({
    status: "ACTIVE",
    service: "Pharoah ERP Bidirectional Cloud Relay Engine",
    version: "1.0.9",
    timestamp: new Date().toISOString()
  });
}

function handlePullRequest(storeToken, username, password, folder) {
  var cleanToken = (storeToken || "").trim().toUpperCase();
  var inputUser = (username || "").trim().toLowerCase();
  var inputPass = (password || "").trim();

  if (!cleanToken) {
    return createJsonResponse({ status: "ERROR", message: "Store Key is required." });
  }

  var fileName = cleanToken + ".json";
  var files = folder.getFilesByName(fileName);

  if (!files.hasNext()) {
    return createJsonResponse({
      status: "ERROR",
      message: "Store Key not found. Please tap 'SYNC NOW' in your app first."
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
      message: "Invalid Username or Password for Store Key: " + cleanToken
    });
  }
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
