package com.quickchat.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class AdminAuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        HttpSession session = req.getSession(false);
        
        String uri = req.getRequestURI();
        
        // Pages publiques
        if (uri.contains("/login") || uri.contains("/css/") || uri.contains("/js/") || 
            uri.contains("/images/") || uri.contains("/uploads/") || uri.contains("/avatars/")) {
            chain.doFilter(request, response);
            return;
        }
        
        // Vérifier si admin connecté
        boolean isLoggedIn = false;
        if (session != null && session.getAttribute("adminId") != null) {
            isLoggedIn = true;
        }
        
        if (!isLoggedIn) {
        	res.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}