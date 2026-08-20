/* ============================================================================
   FILE      : 06-java-gui/LendingPlatform.java
   MODULE    : Java JDBC + Swing Desktop Client ("Community Lending Hub")
   ----------------------------------------------------------------------------
   OBJECTIVE & RELATIONAL CONCEPT
     A single-window Swing front end that performs full CRUD against the
     ITEMS catalog table (see items_table.sql) through JDBC.
       * JDBC connection lifecycle : DriverManager + explicit close on exit.
       * PreparedStatement binding : every user input is a bind parameter
                                     (?, ?, ?, ?) -- SQL-injection proof.
       * DML vs Query handling     : executeUpdate() returns affected-row
                                     counts (drives "not found" UX), while
                                     executeQuery() streams a ResultSet.
       * GUI architecture          : BorderLayout shell, GridLayout form,
                                     JOptionPane feedback, EDT-safe launch.

   ----------------------------------------------------------------------------
   TECHNICAL LOGIC BREAKDOWN
     1. Constructor builds the header / form / button grid, then opens the
        connection. URL, user and password come from ENVIRONMENT VARIABLES
        (DB_URL / DB_USER / DB_PASSWORD) -- sanitised from the original lab
        dump, which hard-coded a live password. Never commit credentials.
     2. Add Item      -> INSERT INTO ITEMS VALUES (?,?,?,?)
        Update Price  -> UPDATE ITEMS SET PRICE_PER_DAY=? WHERE ITEM_ID=?
                         (rows == 0  =>  "Item ID not found!")
        Remove Item   -> prompt for ID, then DELETE ... WHERE ITEM_ID=?
        View Catalog  -> SELECT * FROM ITEMS streamed into a JTextArea.
     3. A WindowAdapter closes the Connection on exit; Swing is started on
        the Event Dispatch Thread via SwingUtilities.invokeLater.

     Connectivity note: defaults target Oracle XE (ojdbc11). The original lab
     used MySQL Connector/J; to reproduce that setup, set:
       DB_URL=jdbc:mysql://localhost:3306/lending_db
     and uncomment the Class.forName line below.

   ----------------------------------------------------------------------------
   SAMPLE EXPECTED INPUT / OUTPUT
     Build & run:
       $ javac LendingPlatform.java
       $ java  -cp .:ojdbc11.jar LendingPlatform
     UI flow:
       * Fill "Item ID: 101 / Item Name: Concrete Mixer / Category: Machines /
         Price/Day: 800" -> [Add Item]    -> dialog "Item added to catalog!"
       * Set ID 101 + price 850 -> [Update Price]  -> "Price updated!"
       * [View Catalog] -> scrollable dialog listing every catalog row
       * [Remove Item] -> input "101" -> "Item removed!"
   ========================================================================== */

import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class LendingPlatform extends JFrame {

    /* ---- Externalised configuration: no secrets in source control -------- */
    private static final String DB_URL = System.getenv().getOrDefault(
            "DB_URL", "jdbc:oracle:thin:@//localhost:1521/XEPDB1");
    private static final String DB_USER = System.getenv().getOrDefault(
            "DB_USER", "LENDING_APP");
    private static final String DB_PASSWORD = System.getenv().getOrDefault(
            "DB_PASSWORD", "");

    private JTextField t1, t2, t3, t4;
    private JButton insertBtn, updateBtn, deleteBtn, viewBtn;
    private Connection con;

    public LendingPlatform() {
        setTitle("Local Lending Platform");
        setSize(520, 450);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLayout(new BorderLayout());

        /* ---------------- Header --------------------------------------- */
        JLabel title = new JLabel("Community Lending Hub", JLabel.CENTER);
        title.setFont(new Font("Segoe UI", Font.BOLD, 22));
        title.setBorder(BorderFactory.createEmptyBorder(15, 10, 10, 10));
        add(title, BorderLayout.NORTH);

        /* ---------------- Form panel ----------------------------------- */
        JPanel form = new JPanel(new GridLayout(4, 2, 10, 15));
        form.setBorder(BorderFactory.createEmptyBorder(20, 40, 20, 40));
        form.setBackground(new Color(240, 245, 240));

        Font f = new Font("Segoe UI", Font.PLAIN, 14);

        form.add(new JLabel("Item ID:"));
        t1 = new JTextField(); t1.setFont(f); form.add(t1);

        form.add(new JLabel("Item Name:"));
        t2 = new JTextField(); t2.setFont(f); form.add(t2);

        form.add(new JLabel("Category:"));
        t3 = new JTextField(); t3.setFont(f); form.add(t3);

        form.add(new JLabel("Price/Day ($):"));
        t4 = new JTextField(); t4.setFont(f); form.add(t4);

        add(form, BorderLayout.CENTER);

        /* ---------------- Buttons panel -------------------------------- */
        JPanel buttons = new JPanel(new GridLayout(2, 2, 12, 12));
        buttons.setBorder(BorderFactory.createEmptyBorder(10, 40, 20, 40));

        insertBtn = new JButton("Add Item");
        updateBtn = new JButton("Update Price");
        deleteBtn = new JButton("Remove Item");
        viewBtn   = new JButton("View Catalog");

        JButton[] btns = {insertBtn, updateBtn, deleteBtn, viewBtn};
        for (JButton b : btns) {
            b.setFont(new Font("Segoe UI", Font.BOLD, 13));
            b.setFocusPainted(false);
            b.setBackground(new Color(220, 230, 220));
        }

        buttons.add(insertBtn); buttons.add(updateBtn);
        buttons.add(deleteBtn); buttons.add(viewBtn);
        add(buttons, BorderLayout.SOUTH);

        /* ---------------- JDBC connection ------------------------------- */
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            /* MySQL variant used in the original lab:
               Class.forName("com.mysql.cj.jdbc.Driver");                 */
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this,
                    "DB Connection Error: " + e.getMessage());
        }

        /* ---------------- CRUD wiring (all bind-parameterised) ---------- */

        insertBtn.addActionListener(e -> {
            String sql = "INSERT INTO ITEMS VALUES (?,?,?,?)";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, t1.getText());
                ps.setString(2, t2.getText());
                ps.setString(3, t3.getText());
                ps.setFloat(4, Float.parseFloat(t4.getText()));
                ps.executeUpdate();
                JOptionPane.showMessageDialog(this, "Item added to catalog!");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Error: " + ex.getMessage());
            }
        });

        updateBtn.addActionListener(e -> {
            String sql = "UPDATE ITEMS SET PRICE_PER_DAY=? WHERE ITEM_ID=?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setFloat(1, Float.parseFloat(t4.getText()));
                ps.setString(2, t1.getText());
                int rows = ps.executeUpdate();
                JOptionPane.showMessageDialog(this,
                        rows > 0 ? "Price updated!" : "Item ID not found!");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, ex.getMessage());
            }
        });

        deleteBtn.addActionListener(e -> {
            String id = JOptionPane.showInputDialog(this,
                    "Enter Item ID to remove:");
            if (id == null || id.isEmpty()) return;
            String sql = "DELETE FROM ITEMS WHERE ITEM_ID=?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, id);
                int rows = ps.executeUpdate();
                JOptionPane.showMessageDialog(this,
                        rows > 0 ? "Item removed!" : "Item not found!");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, ex.getMessage());
            }
        });

        viewBtn.addActionListener(e -> {
            String sql = "SELECT * FROM ITEMS";
            try (Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery(sql)) {
                StringBuilder data =
                        new StringBuilder("--- CURRENT INVENTORY ---\n\n");
                while (rs.next()) {
                    data.append("ID: ").append(rs.getString(1))
                        .append(" | ").append(rs.getString(2))
                        .append("\nCategory: ").append(rs.getString(3))
                        .append("\nRate: $").append(rs.getFloat(4))
                        .append("/day\n")
                        .append("----------------------------\n");
                }
                JTextArea area = new JTextArea(data.toString());
                area.setEditable(false);
                JOptionPane.showMessageDialog(this, new JScrollPane(area),
                        "Catalog", JOptionPane.PLAIN_MESSAGE);
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, ex.getMessage());
            }
        });

        /* ---------------- Release the connection with the window -------- */
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent e) {
                try {
                    if (con != null) con.close();
                } catch (Exception ex) {
                    /* nothing sensible to do while the JVM is exiting */
                }
            }
        });

        setVisible(true);
    }

    public static void main(String[] args) {
        /* All Swing component work must happen on the EDT */
        SwingUtilities.invokeLater(LendingPlatform::new);
    }
}
