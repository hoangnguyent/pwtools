<%@page import="java.io.*"%>
 
<%
//-------------------------------------------------------------------------------------------------------------------------
//------------------------------- SETTINGS --------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------

	// pwadmin access password as md5 encrypted string
	// generate a md5 encrypted password e.g. https://www.md5online.org/md5-encrypt.html
String algorithm = "md5AndThenBase64encode";
String iweb_password = "179edfe73d9c016b51e9dc77ae0eebb1";

	// connection settings to the mysql pw database
String db_host = "localhost";
String db_port = "3306";
String db_user = "admin";
String db_password = "admin";
String db_database = "pw";

	// Type of your items database required for mapping id's to names
	// Options are my or pwi
	String item_labels = "pwi";

	// Absolute path to your PW-Server main directory (startscript, stopscript, /gamed)
	// requires a tailing slash
String pw_server_path = "/root/home/";

	// If you have hundreds of characters or heavy web access through this site
	// It is recommend to turn the realtime character list feature off (false)
	// to prevent server from overload injected by character list generation
	boolean enable_character_list = true;

	String pw_server_name = "home";
	String pw_server_description = "#";

//-------------------------------------------------------------------------------------------------------------------------
//----------------------------- END SETTINGS ------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------

	String pw_server_exp = "1";
	String pw_server_sp = "1";
	String pw_server_drop = "1";
	String pw_server_coins = "1";

	BufferedReader bfr = null;
	String row;

	if(request.getSession().getAttribute("items") == null)
	{
		String[] items = new String[30001];

		try
		{
			bfr = new BufferedReader(new InputStreamReader(new FileInputStream(new File(request.getRealPath("/include/items") + "/default.dat")), "UTF8"));
			if(item_labels.compareTo("my") == 0)
			{
				bfr = new BufferedReader(new InputStreamReader(new FileInputStream(new File(request.getRealPath("/include/items") + "/my.dat")), "UTF8"));
			}
			if(item_labels.compareTo("pwi") == 0)
			{
				bfr = new BufferedReader(new InputStreamReader(new FileInputStream(new File(request.getRealPath("/include/items") + "/pwi.dat")), "UTF8"));
			}
			int count = 0;
			while((row = bfr.readLine()) != null && count < 30001)
			{
				items[count] = row;
				count++;
			}
			bfr.close();
		}
		catch(Exception e)
		{
		}

		request.getSession().setAttribute("items", items);
	}
%>
