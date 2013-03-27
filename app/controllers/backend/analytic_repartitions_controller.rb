class Backend::AnalyticRepartitionsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :affected_on
    t.column :name, :through => :activity, :url => true
    t.column :name, :through => :product_nature, :url => true
    t.column :name, :through => :campaign, :url => true
    #t.column :id, :through => :journal_entry_item, :url => true
    t.column :state
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of analytic_repartitions.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => AnalyticRepartition.all }
      format.json { render :json => AnalyticRepartition.all }
    end
  end

  # Displays the page for one analytic_repartition.
  def show
    return unless @analytic_repartition = find_and_check
    respond_to do |format|
      format.html { t3e(@analytic_repartition) }
      format.xml  { render :xml => @analytic_repartition }
      format.json { render :json => @analytic_repartition }
    end
  end

end
