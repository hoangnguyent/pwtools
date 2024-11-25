<%@page contentType="text/html; charset=GBK"%>
<%@page import="java.lang.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.*"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="protocol.*"%>
<%@page import="com.goldhuman.auth.*"%>
<%@page import="com.goldhuman.util.*"%>
<%@page import="org.apache.commons.logging.Log"%>
<%@page import="org.apache.commons.logging.LogFactory"%>
<%@page import="java.sql.*"%>
<%
	// ORIGINALLY CODED BY MARHAZK (MARHAZK@YAHOO.COM) 
	// SUPPORTED PW-UWEB v3.5 MODULE (www.perfectworld.sytes.net/pwuweb)
	// COPYRIGHT ALL RIGHT RESERVED BY MARHAZK
	// DEVELOPMENT TEAM : MMORPG-DEV (www.mmorpg-dev.com)
	// VERSION: V2.0
	// FIRST RELEASE: MSSQL ONLY
	// NOTES: MODIFYING THIS PAGE OR/AND REMOVE THE COMMENTS THAT CONTAIN "MarHazK" NAME AS ORIGINAL CODER ARE ILLEGAL UNDER GNU LICENSES
	//
	//
	//
	// SQL INFORMATION
	//
	// NOTES: PLEASE EDIT YOUR <IP ADDRESS>, <USERNAME>, AND <PASSWORD> TO MAKE IT FUNCTIONING
	//
	// for mysql by ADSLPREDATOR, 2008
	// with little changes in code

      Connection connection = null;
      Class.forName("com.mysql.jdbc.Driver");
	  //Class.forName("com.goldhuman.util.MySqlCon");
    
      connection = DriverManager.getConnection("jdbc:mysql://localhost:3306/dbo?useUnicode=true&characterEncoding=utf8", "root", "root");
	Statement statement = connection.createStatement();
	
	//
	//CLEAR UWEBPLAYERS DATABASE
	//	
	String deleteall = "DELETE FROM uwebplayers";
	statement.executeUpdate(deleteall);

	//
	//GET USER DB FIRST
	//
	ResultSet rst=null;
	rst = statement.executeQuery("select ID from users ORDER BY ID DESC");

	RoleBean role = null;
	String tempplayername = null;
	String command = null;
	int index = 0;
	int maxid = 0;
	int roleid = 31;
	int uid = 0;
	int eachacc = 0;
	while (rst.next())
	{
		maxid = Integer.parseInt(rst.getString("ID"));
		break;
	}
	
	while (roleid <= maxid)
	{
		roleid++;
		eachacc++;
		try
		{
			if (eachacc < 16) // ADSLPREDATOR
			{
				role = GameDB.get( roleid );
				session.setAttribute( "gamedb_rolebean", role );
				if (null == role){
					continue;
				}
				else
				{
					tempplayername = null;
					tempplayername = StringEscapeUtils.escapeHtml(role.base.name.getString());
					
					index = 0;
					index = tempplayername.indexOf("'");
					StringBuffer playername = new StringBuffer(tempplayername);
					if(index > 0){
						playername.replace(index, index + 1, "?");
					}
						
					command = "INSERT INTO uwebplayers (roleid, rolename, rolelevel, rolestatus, rolegender, roleprof, rolerep, redname, rednametime, pinknametime) VALUES ("+roleid+", '"+playername+"', " + role.status.level + ", '" + role.base.status + "', '" + role.base.gender + "', '" + role.base.cls + "', '" + role.status.reputation + "', '" + role.status.invader_state + "', '" + role.status.invader_time + "', '" + role.status.pariah_time + "')";
					statement.executeUpdate(command);
					out.println("<br>--100% stored RoleDB: Name:" + tempplayername + " Roleid:" + roleid + " Level:" + role.status.level);
					//out.println(command);
				}
			}
			else if (eachacc == 16) // ADSLPREDATOR
				eachacc = 0;
			else
				continue;
		}
		catch (Exception e)
		{
			continue;
		}
	}
	
%>

// <%
// String redirectURL = "http://192.168.8.129/rank/index.php";
// response.sendRedirect(redirectURL);
// %>
