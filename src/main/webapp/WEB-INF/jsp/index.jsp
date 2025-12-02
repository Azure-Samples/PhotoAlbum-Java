<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Photo Gallery - Photo Album</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" />
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/site.css" />
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-sm navbar-toggleable-sm navbar-dark bg-dark border-bottom box-shadow mb-3">
            <div class="container">
                <a class="navbar-brand" href="${pageContext.request.contextPath}/">&#128248; Photo Album</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target=".navbar-collapse"
                        aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="navbar-collapse collapse d-sm-inline-flex justify-content-between">
                    <ul class="navbar-nav flex-grow-1">
                        <li class="nav-item">
                            <a class="nav-link text-light" href="${pageContext.request.contextPath}/">Gallery</a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
    </header>

    <div class="container">
        <main role="main" class="pb-3">
            <div class="mb-4">
                <h1 class="display-4">&#128248; Photo Gallery</h1>
                <p class="lead">Upload and view your photos</p>
            </div>

            <!-- Success/Error Messages -->
            <c:if test="${param.success == 'uploaded'}">
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    Photo uploaded successfully!
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            </c:if>

            <c:if test="${param.success == 'deleted'}">
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    Photo deleted successfully!
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            </c:if>

            <c:if test="${param.error != null}">
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <c:choose>
                        <c:when test="${param.error == 'nofile'}">Please select a file to upload.</c:when>
                        <c:when test="${param.error == 'invalidtype'}">Invalid file type. Only images are allowed.</c:when>
                        <c:when test="${param.error == 'database'}">Database error occurred.</c:when>
                        <c:when test="${param.error == 'notfound'}">Photo not found.</c:when>
                        <c:otherwise>An error occurred.</c:otherwise>
                    </c:choose>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            </c:if>

            <!-- Upload Zone -->
            <div class="card mb-4">
                <div class="card-body">
                    <h5 class="card-title">Upload Photos</h5>
                    <form id="upload-form" method="post" action="${pageContext.request.contextPath}/upload" enctype="multipart/form-data">
                        <div id="drop-zone" class="drop-zone mb-3">
                            <div class="drop-zone-content">
                                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" class="bi bi-cloud-upload mb-3" viewBox="0 0 16 16">
                                    <path fill-rule="evenodd" d="M4.406 1.342A5.53 5.53 0 0 1 8 0c2.69 0 4.923 2 5.166 4.579C14.758 4.804 16 6.137 16 7.773 16 9.569 14.502 11 12.687 11H10a.5.5 0 0 1 0-1h2.688C13.979 10 15 8.988 15 7.773c0-1.216-1.02-2.228-2.313-2.228h-.5v-.5C12.188 2.825 10.328 1 8 1a4.53 4.53 0 0 0-2.941 1.1c-.757.652-1.153 1.438-1.153 2.055v.448l-.445.049C2.064 4.805 1 5.952 1 7.318 1 8.785 2.23 10 3.781 10H6a.5.5 0 0 1 0 1H3.781C1.708 11 0 9.366 0 7.318c0-1.763 1.266-3.223 2.942-3.593.143-.863.698-1.723 1.464-2.383z"/>
                                    <path fill-rule="evenodd" d="M7.646 4.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1-.708.708L8.5 5.707V14.5a.5.5 0 0 1-1 0V5.707L5.354 7.854a.5.5 0 1 1-.708-.708l3-3z"/>
                                </svg>
                                <p class="mb-2"><strong>Drag and drop photos here</strong></p>
                                <p class="text-muted small">or click to select files</p>
                                <p class="text-muted small">Supports: JPEG, PNG, GIF, WebP (max 10MB each)</p>
                            </div>
                            <input type="file" id="file-input" name="file" accept="image/jpeg,image/png,image/gif,image/webp" hidden />
                        </div>

                        <button type="submit" class="btn btn-primary" id="upload-btn" disabled>
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-upload" viewBox="0 0 16 16">
                                <path d="M.5 9.9a.5.5 0 0 1 .5.5v2.5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-2.5a.5.5 0 0 1 1 0v2.5a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2v-2.5a.5.5 0 0 1 .5-.5z"/>
                                <path d="M7.646 1.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1-.708.708L8.5 2.707V11.5a.5.5 0 0 1-1 0V2.707L5.354 4.854a.5.5 0 1 1-.708-.708l3-3z"/>
                            </svg>
                            Upload
                        </button>
                    </form>
                </div>
            </div>

            <!-- Gallery -->
            <div id="gallery-section">
                <c:if test="${empty photos}">
                    <div class="alert alert-info text-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" class="bi bi-images mb-3" viewBox="0 0 16 16">
                            <path d="M4.502 9a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/>
                            <path d="M14.002 13a2 2 0 0 1-2 2h-10a2 2 0 0 1-2-2V5A2 2 0 0 1 2 3a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v8a2 2 0 0 1-1.998 2zM14 2H4a1 1 0 0 0-1 1h9.002a2 2 0 0 1 2 2v7A1 1 0 0 0 15 11V3a1 1 0 0 0-1-1zM2.002 4a1 1 0 0 0-1 1v8l2.646-2.354a.5.5 0 0 1 .63-.062l2.66 1.773 3.71-3.71a.5.5 0 0 1 .577-.094l1.777 1.947V5a1 1 0 0 0-1-1h-10z"/>
                        </svg>
                        <p class="mb-0">No photos yet. Upload your first photo to get started!</p>
                    </div>
                </c:if>

                <c:if test="${not empty photos}">
                    <div class="row" id="photo-gallery">
                        <c:forEach var="photo" items="${photos}">
                            <div class="col-12 col-sm-6 col-md-4 col-lg-3 mb-4">
                                <div class="card photo-card h-100">
                                    <a href="${pageContext.request.contextPath}/detail?id=${photo.id}" class="photo-link">
                                        <img src="${pageContext.request.contextPath}/download?id=${photo.id}" class="card-img-top" alt="${fn:escapeXml(photo.originalFileName)}" loading="lazy">
                                    </a>
                                    <div class="card-body">
                                        <p class="card-text text-truncate" title="${fn:escapeXml(photo.originalFileName)}">
                                            <small><a href="${pageContext.request.contextPath}/detail?id=${photo.id}" class="text-decoration-none text-dark">${fn:escapeXml(photo.originalFileName)}</a></small>
                                        </p>
                                        <p class="card-text">
                                            <small class="text-muted"><fmt:formatDate value="${photo.uploadedAt}" pattern="MMM dd, yyyy h:mm a" /></small>
                                        </p>
                                        <p class="card-text">
                                            <small class="text-muted">
                                                <fmt:formatNumber value="${photo.fileSize / 1024}" maxFractionDigits="0" /> KB
                                                <c:if test="${photo.width != null && photo.height != null}">
                                                    &#8226; ${photo.width} x ${photo.height}
                                                </c:if>
                                            </small>
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                    </div>
                </c:if>
            </div>
        </main>
    </div>

    <footer class="border-top footer text-muted">
        <div class="container">
            &copy; 2025 - Photo Album - A simple photo storage application
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="${pageContext.request.contextPath}/js/upload.js"></script>
</body>
</html>
