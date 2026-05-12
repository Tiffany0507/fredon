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

public class CacheControlFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        
        String uri = req.getRequestURI();
        
        // Ne pas appliquer aux ressources statiques et à la page login
        if (uri.contains("/css/") || uri.contains("/js/") || uri.contains("/images/") ||
            uri.contains("/uploads/") || uri.contains("/avatars/") || uri.contains("/includes/") ||
            uri.contains("/login")) {
            chain.doFilter(request, response);
            return;
        }
        
        // Désactiver la mise en cache
        res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setHeader("Expires", "0");
        
        // Vérifier si l'utilisateur est connecté
        HttpSession session = req.getSession(false);
        boolean isLoggedIn = (session != null && session.getAttribute("adminId") != null);
        
        if (!isLoggedIn) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}