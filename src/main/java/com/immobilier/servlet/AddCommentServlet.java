package com.immobilier.servlet;

import com.immobilier.dao.CommentDAO;
import com.immobilier.model.Comment;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

@WebServlet("/add-comment")
public class AddCommentServlet extends HttpServlet {

	private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
	private static final String DB_USER = "root";
	private static final String DB_PASSWORD = "";

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String propertyIdStr = request.getParameter("propertyId");
		String visitorName = request.getParameter("visitorName");
		String visitorEmail = request.getParameter("visitorEmail");
		String content = request.getParameter("content");

		// Validation
		if (propertyIdStr == null || propertyIdStr.trim().isEmpty() || visitorName == null
				|| visitorName.trim().isEmpty() || content == null || content.trim().isEmpty()) {

			response.sendRedirect(request.getHeader("Referer") + "?error=missing_fields");
			return;
		}

		// Validation email simple
		if (visitorEmail != null && !visitorEmail.trim().isEmpty()) {
			if (!visitorEmail.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
				response.sendRedirect(request.getHeader("Referer") + "?error=invalid_email");
				return;
			}
		}

		try {
			int propertyId = Integer.parseInt(propertyIdStr);

			Class.forName("com.mysql.cj.jdbc.Driver");

			try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
				CommentDAO commentDAO = new CommentDAO(conn);

				Comment comment = new Comment();
				comment.setPropertyId(propertyId);
				comment.setVisitorName(visitorName.trim());
				comment.setVisitorEmail(visitorEmail != null ? visitorEmail.trim() : null);
				comment.setContent(content.trim());
				comment.setApproved(true); // Auto-approbation, peut être changé à false pour modération

				boolean added = commentDAO.addComment(comment);

				if (added) {
					response.sendRedirect(request.getHeader("Referer") + "?success=comment_added");
				} else {
					response.sendRedirect(request.getHeader("Referer") + "?error=add_failed");
				}
			}

		} catch (NumberFormatException e) {
			response.sendRedirect(request.getHeader("Referer") + "?error=invalid_property");
		} catch (SQLException | ClassNotFoundException e) {
			e.printStackTrace();
			response.sendRedirect(request.getHeader("Referer") + "?error=database_error");
		}
	}
}