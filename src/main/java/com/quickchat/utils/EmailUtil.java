package com.quickchat.utils;

import java.util.Properties;
import javax.mail.*;
import javax.mail.internet.*;

public class EmailUtil {
    
    // ⚠️ REMPLACE AVEC TES INFOS ⚠️
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";
    private static final String EMAIL_FROM = "tiffanymaharo@gmail.com";
    private static final String EMAIL_PASSWORD = "qqbm rblf lfih ssjs";   
    
    public static boolean sendResetCode(String toEmail, String code, String username) {
        Properties props = new Properties();
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        
        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(EMAIL_FROM, EMAIL_PASSWORD);
            }
        });
        
        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(EMAIL_FROM, "Fredon Agence Immobilière"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject("🔐 Fredon - Réinitialisation de votre mot de passe");
            
            String htmlContent = getFredonEmailTemplate(username, code);
            message.setContent(htmlContent, "text/html; charset=utf-8");
            
            Transport.send(message);
            return true;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    private static String getFredonEmailTemplate(String username, String code) {
        return "<!DOCTYPE html>\n" +
               "<html lang=\"fr\">\n" +
               "<head>\n" +
               "  <meta charset=\"UTF-8\">\n" +
               "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" +
               "  <title>Fredon - Réinitialisation mot de passe</title>\n" +
               "  <style>\n" +
               "    @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap');\n" +
               "    * { margin: 0; padding: 0; box-sizing: border-box; }\n" +
               "    body {\n" +
               "      font-family: 'DM Sans', sans-serif;\n" +
               "      background: linear-gradient(135deg, #0a1d58 0%, #1a3aaa 50%, #0e2d82 100%);\n" +
               "      padding: 40px 20px;\n" +
               "    }\n" +
               "    .email-container {\n" +
               "      max-width: 560px;\n" +
               "      margin: 0 auto;\n" +
               "      background: #ffffff;\n" +
               "      border-radius: 28px;\n" +
               "      overflow: hidden;\n" +
               "      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.35);\n" +
               "    }\n" +
               "    .email-header {\n" +
               "      background: linear-gradient(135deg, #0e2d82, #1f52d4);\n" +
               "      padding: 28px 25px;\n" +
               "      text-align: center;\n" +
               "      border-bottom: 3px solid #e8a820;\n" +
               "    }\n" +
               "    .logo-wrapper {\n" +
               "      display: flex;\n" +
               "      align-items: center;\n" +
               "      justify-content: center;\n" +
               "      gap: 12px;\n" +
               "      margin-bottom: 10px;\n" +
               "    }\n" +
               "    .logo-icon {\n" +
               "      font-size: 42px;\n" +
               "      line-height: 1;\n" +
               "    }\n" +
               "    .logo-text {\n" +
               "      font-family: 'Syne', sans-serif;\n" +
               "      font-weight: 800;\n" +
               "      font-size: 32px;\n" +
               "      color: white;\n" +
               "    }\n" +
               "    .logo-sub {\n" +
               "      font-size: 9px;\n" +
               "      color: rgba(255,255,255,0.6);\n" +
               "      letter-spacing: 3px;\n" +
               "      text-transform: uppercase;\n" +
               "      margin-top: 5px;\n" +
               "    }\n" +
               "    .msg-icon {\n" +
               "      text-align: center;\n" +
               "      font-size: 48px;\n" +
               "      margin: 15px 0 10px;\n" +
               "    }\n" +
               "    .email-body {\n" +
               "      padding: 35px 32px;\n" +
               "      background: #ffffff;\n" +
               "    }\n" +
               "    .greeting {\n" +
               "      font-size: 22px;\n" +
               "      font-weight: 700;\n" +
               "      font-family: 'Syne', sans-serif;\n" +
               "      color: #111520;\n" +
               "      margin-bottom: 12px;\n" +
               "    }\n" +
               "    .message {\n" +
               "      color: #4b4637;\n" +
               "      line-height: 1.65;\n" +
               "      margin: 18px 0;\n" +
               "      font-size: 14px;\n" +
               "    }\n" +
               "    .code-box {\n" +
               "      background: linear-gradient(135deg, #f7f5f0, #ede9e0);\n" +
               "      border-radius: 16px;\n" +
               "      padding: 20px;\n" +
               "      text-align: center;\n" +
               "      margin: 25px 0;\n" +
               "      border: 1px solid rgba(31,82,212,0.15);\n" +
               "    }\n" +
               "    .code-label {\n" +
               "      font-size: 11px;\n" +
               "      font-weight: 700;\n" +
               "      letter-spacing: 2px;\n" +
               "      text-transform: uppercase;\n" +
               "      color: #9b9080;\n" +
               "      margin-bottom: 12px;\n" +
               "    }\n" +
               "    .code-value {\n" +
               "      font-size: 36px;\n" +
               "      font-weight: 800;\n" +
               "      font-family: 'Syne', sans-serif;\n" +
               "      color: #1f52d4;\n" +
               "      letter-spacing: 8px;\n" +
               "      background: white;\n" +
               "      padding: 15px;\n" +
               "      border-radius: 12px;\n" +
               "      display: inline-block;\n" +
               "      box-shadow: 0 2px 8px rgba(0,0,0,0.05);\n" +
               "    }\n" +
               "    .security-note {\n" +
               "      background: rgba(31,82,212,0.05);\n" +
               "      padding: 14px 16px;\n" +
               "      border-radius: 12px;\n" +
               "      margin: 20px 0;\n" +
               "      border-left: 3px solid #e8a820;\n" +
               "      font-size: 11px;\n" +
               "      color: #6070a0;\n" +
               "    }\n" +
               "    .security-note span {\n" +
               "      font-size: 14px;\n" +
               "      margin-right: 8px;\n" +
               "    }\n" +
               "    .email-footer {\n" +
               "      background: #f7f5f0;\n" +
               "      padding: 22px 32px;\n" +
               "      text-align: center;\n" +
               "      border-top: 1px solid rgba(0,0,0,0.05);\n" +
               "    }\n" +
               "    .footer-text {\n" +
               "      font-size: 10px;\n" +
               "      color: #9b9080;\n" +
               "      line-height: 1.5;\n" +
               "    }\n" +
               "    .heart {\n" +
               "      color: #dc2626;\n" +
               "    }\n" +
               "    .gold-text {\n" +
               "      color: #b8900e;\n" +
               "    }\n" +
               "    .house-icon {\n" +
               "      font-size: 46px;\n" +
               "      text-align: center;\n" +
               "      margin-bottom: 10px;\n" +
               "    }\n" +
               "  </style>\n" +
               "</head>\n" +
               "<body>\n" +
               "  <div class=\"email-container\">\n" +
               "    <div class=\"email-header\">\n" +
               "      <div class=\"logo-wrapper\">\n" +
               "        <div class=\"logo-icon\">🏠</div>\n" +
               "        <div>\n" +
               "          <div class=\"logo-text\">Fredon</div>\n" +
               "          <div class=\"logo-sub\">AGENCE IMMOBILIÈRE</div>\n" +
               "        </div>\n" +
               "      </div>\n" +
               "    </div>\n" +
               "    \n" +
               "    <div class=\"email-body\">\n" +
               "      <div class=\"house-icon\">🏡</div>\n" +
               "      <div class=\"msg-icon\">📧</div>\n" +
               "      <div class=\"greeting\">Bonjour <span class=\"gold-text\">" + escapeHtml(username) + "</span> 👋</div>\n" +
               "      \n" +
               "      <div class=\"message\">\n" +
               "        Nous avons reçu une demande de réinitialisation de votre mot de passe pour votre compte <strong>Fredon Agence Immobilière</strong>.\n" +
               "      </div>\n" +
               "      \n" +
               "      <div class=\"code-box\">\n" +
               "        <div class=\"code-label\">🔐 VOTRE CODE DE VÉRIFICATION</div>\n" +
               "        <div class=\"code-value\">" + code + "</div>\n" +
               "      </div>\n" +
               "      \n" +
               "      <div class=\"message\">\n" +
               "        Ce code est valable pendant <strong>15 minutes</strong>. Entrez-le sur la page de réinitialisation pour créer un nouveau mot de passe.\n" +
               "      </div>\n" +
               "      \n" +
               "      <div class=\"security-note\">\n" +
               "        <span>🔒</span> Si vous n'avez pas demandé cette réinitialisation, ignorez cet email. Votre mot de passe restera inchangé.\n" +
               "      </div>\n" +
               "    </div>\n" +
               "    \n" +
               "    <div class=\"email-footer\">\n" +
               "      <div class=\"footer-text\">\n" +
               "        <p>© 2026 Fredon — Agence Immobilière Madagascar</p>\n" +
               "        <p>Votre partenaire de confiance pour l'immobilier</p>\n" +
               "        <p style=\"margin-top: 12px;\">Fait avec <span class=\"heart\">❤️</span> à Mahajanga</p>\n" +
               "      </div>\n" +
               "    </div>\n" +
               "  </div>\n" +
               "</body>\n" +
               "</html>";
    }
    
    private static String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
}