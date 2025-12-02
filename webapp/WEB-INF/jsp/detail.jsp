<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${not empty photo ? fn:escapeXml(photo.originalFileName) : 'Photo Detail'} - Photo Album</title>
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
            <c:if test="${empty photo}">
                <div class="alert alert-warning">
                    <h4>Photo not found</h4>
                    <p>The photo you're looking for doesn't exist or has been deleted.</p>
                    <a href="${pageContext.request.contextPath}/" class="btn btn-primary">Back to Gallery</a>
                </div>
            </c:if>

            <c:if test="${not empty photo}">
                <div class="photo-detail-container">
                    <!-- Header with back button -->
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <a href="${pageContext.request.contextPath}/" class="btn btn-outline-secondary">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-left" viewBox="0 0 16 16">
                                <path fill-rule="evenodd" d="M15 8a.5.5 0 0 0-.5-.5H2.707l3.147-3.146a.5.5 0 1 0-.708-.708l-4 4a.5.5 0 0 0 0 .708l4 4a.5.5 0 0 0 .708-.708L2.707 8.5H14.5A.5.5 0 0 0 15 8z"/>
                            </svg>
                            Back to Gallery
                        </a>

                        <form method="post" action="${pageContext.request.contextPath}/detail"
                              onsubmit="return confirm('Are you sure you want to delete this photo?');">
                            <input type="hidden" name="id" value="${photo.id}" />
                            <input type="hidden" name="action" value="delete" />
                            <button type="submit" class="btn btn-danger">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-trash" viewBox="0 0 16 16">
                                    <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/>
                                    <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/>
                                </svg>
                                Delete
                            </button>
                        </form>
                    </div>

                    <!-- Main photo display -->
                    <div class="row">
                        <div class="col-lg-8 mb-4">
                            <div class="card">
                                <div class="card-body p-0">
                                    <img src="${pageContext.request.contextPath}/download?id=${photo.id}"
                                         alt="${fn:escapeXml(photo.originalFileName)}"
                                         class="img-fluid w-100 photo-detail-image"
                                         style="max-height: 80vh; object-fit: contain; background-color: #f8f9fa;">
                                </div>
                            </div>

                            <!-- Download button -->
                            <div class="mt-3">
                                <a href="${pageContext.request.contextPath}/download?id=${photo.id}&mode=download" class="btn btn-primary">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-download" viewBox="0 0 16 16">
                                        <path d="M.5 9.9a.5.5 0 0 1 .5.5v2.5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-2.5a.5.5 0 0 1 1 0v2.5a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2v-2.5a.5.5 0 0 1 .5-.5z"/>
                                        <path d="M7.646 11.854a.5.5 0 0 0 .708 0l3-3a.5.5 0 0 0-.708-.708L8.5 10.293V1.5a.5.5 0 0 0-1 0v8.793L5.354 8.146a.5.5 0 1 0-.708.708l3 3z"/>
                                    </svg>
                                    Download Original
                                </a>
                            </div>
                        </div>

                        <!-- Photo information sidebar -->
                        <div class="col-lg-4">
                            <div class="card">
                                <div class="card-header">
                                    <h5 class="mb-0">Photo Information</h5>
                                </div>
                                <div class="card-body">
                                    <dl class="row mb-0">
                                        <dt class="col-sm-5">Filename:</dt>
                                        <dd class="col-sm-7 text-break">${fn:escapeXml(photo.originalFileName)}</dd>

                                        <dt class="col-sm-5">Uploaded:</dt>
                                        <dd class="col-sm-7">
                                            <fmt:formatDate value="${photo.uploadedAt}" pattern="MMM dd, yyyy" /><br/>
                                            <small class="text-muted"><fmt:formatDate value="${photo.uploadedAt}" pattern="h:mm:ss a" /></small>
                                        </dd>

                                        <dt class="col-sm-5">File Size:</dt>
                                        <dd class="col-sm-7">
                                            <c:choose>
                                                <c:when test="${photo.fileSize < 1024}">
                                                    ${photo.fileSize} bytes
                                                </c:when>
                                                <c:when test="${photo.fileSize < 1024 * 1024}">
                                                    <fmt:formatNumber value="${photo.fileSize / 1024.0}" maxFractionDigits="2" minFractionDigits="2" /> KB
                                                </c:when>
                                                <c:otherwise>
                                                    <fmt:formatNumber value="${photo.fileSize / (1024.0 * 1024.0)}" maxFractionDigits="2" minFractionDigits="2" /> MB
                                                </c:otherwise>
                                            </c:choose>
                                        </dd>

                                        <c:if test="${photo.width != null && photo.height != null}">
                                            <dt class="col-sm-5">Dimensions:</dt>
                                            <dd class="col-sm-7">${photo.width} x ${photo.height} px</dd>
                                        </c:if>

                                        <dt class="col-sm-5">Type:</dt>
                                        <dd class="col-sm-7">
                                            <span class="badge bg-secondary">${photo.mimeType}</span>
                                        </dd>
                                    </dl>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </c:if>
        </main>
    </div>

    <footer class="border-top footer text-muted">
        <div class="container">
            &copy; 2025 - Photo Album - A simple photo storage application
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
