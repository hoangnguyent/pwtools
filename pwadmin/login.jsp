<%@page import="java.io.*"%>
<%@page import="java.util.*"%>
<%@page import="java.security.*"%>
<%@page import="org.apache.commons.codec.binary.Base64"%>
<%@page import="org.apache.commons.codec.digest.DigestUtils"%> <!-- apache commons-codec-1.8 support JDK6 -->
<%@include file="WEB-INF/.pwadminconf.jsp"%>

<%!

    String encode(String salt, String algorithm) throws Exception
	{
        salt = salt.toLowerCase();

        if("HexEncoding".equalsIgnoreCase(algorithm)){

            MessageDigest md = MessageDigest.getInstance("MD5");
            md.reset();
            md.update(salt.getBytes());
            byte[] digest = md.digest();
            StringBuffer hashedpasswd = new StringBuffer("0x");
            String hx;
            for (int i = 0; i < digest.length; i++) {
                hx = Integer.toHexString(0xFF & digest[i]);
                // 0x03 is equal to 0x3, but we need 0x03 for our md5sum
                if (hx.length() == 1) {
                    hx = "0" + hx;
                }
                hashedpasswd.append(hx);
            }

            return hashedpasswd.toString();

        } else {

            // Generate MD5 hash
            byte[] hash = DigestUtils.md5(salt);

            // Base64 encode the hash
            return Base64.encodeBase64String(hash);
        }
   	}
%>

<table cellpadding="2" cellspacing="0" border="0">
<tr>
<%
	if(request.getParameter("logout") != null && request.getParameter("logout").compareTo("true") == 0)
	{
		request.getSession().removeAttribute("ssid");
		request.getSession().removeAttribute("items");
	}

	if(request.getParameter("key") != null)
	{
		// compare passwords
        String password = request.getParameter("key");
		if(encode(password, algorithm).compareTo(iweb_password) == 0)
		{
			request.getSession().setAttribute("ssid", request.getRemoteAddr());
		}
	}

	if(request.getSession().getAttribute("ssid") == null)
	{
		//if("0x21232f297a57a5a743894a0e4a801fc3".compareTo(iweb_password) == 0)
		//{
		//	out.println("<td align=\"left\" colspan=\"2\"><b><font color=\"#ff0000\">Change Initial Password</font></b></td></tr><tr>");
		//}
		out.println("<form action=\"index.jsp?page=login\" method=\"post\"><td><input name=\"key\" type=\"password\" style=\"width: 70; text-align: center;\"></input></td><td><input type=\"image\" src=\"include/btn_login.jpg\" style=\"border: 0px;\"></input></td></form>");
	}
	else
	{
		out.println("<td><a href=\"index.jsp?page=login&logout=true\"><img src=\"include/btn_logout.jpg\" border=\"0\"></img></a></td>");
	}
%>
</tr>
</table>